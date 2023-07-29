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

unit SP_Tokenise;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}
{$INCLUDE SpecBAS.inc}

interface

Uses SysUtils, Math, Classes, SP_Util, SP_AnsiStringlist;

Type
  TToken = Packed Record
    Token: Byte;
    Handler: Pointer;
    TokenPos: LongWord;
    TokenLen: LongWord;
    Cache: LongWord;
    BPIndex: Integer;
  End;
  pToken = ^TToken;

  TCompoundWord = Record
    Name: aString;
    KeyWordID: LongWord;
  End;

Function  SP_TokeniseLine(Line: aString; IsExpression, AddLineNum: Boolean): aString;
Function  SP_IsHybridFn(const Idx: LongWord): Boolean;
Function  SP_IsReserved(Const Line: aString): Boolean;
Function  SP_IsConstant(Const Line: aString): Integer;
Function  SP_IsKeyWord(Const Line: aString): Integer;
Function  SP_IsFunction(Const Line: aString): Integer;
Function  SP_GetNumber(Line: aString; Var Idx: Integer; Var Number: aFloat; AllowSpaces: Boolean = False): Boolean;
Function  SP_Detokenise(Tokens: aString; Var cPos: Integer; Highlight, UseDoubles: Boolean): aString;
Function  SP_SyntaxHighlight(CodeLine, PrevSyntax: aString; HasNumber: Boolean; Var AddedChars: Integer): aString;
Function  SP_Store_Line(Tokens: aString): Integer;
Procedure SP_Program_Add(Str: aString);
Procedure SP_Program_AddStrings(List: TAnsiStringList);
Procedure SP_Program_AddStringsArray(Var List: Array of aString);
Procedure SP_Program_Insert(Index: Integer; Str: aString);
Procedure SP_Program_Delete(Index: Integer);
Procedure SP_Program_Delete_Line(Line: Integer);
Procedure SP_Program_Clear;

Var

  Idx_t: Integer;
  TempStr: aString;
  SP_KEYWORDS: Array of aString;
  SP_FUNCTIONS: Array of aString;
  SP_OPTIMISE_FLAGS, SP_OPTIMISE_META_FLAGS: Array of Boolean;
  SP_Program: Array of aString;
  SP_Program_Count: Integer;
  SP_User_Program_Count: Integer;

  SortedTokens: Array of TCompoundWord;
  Hashes: Array[0..26] of Integer;

Const

  // List of keywords that are used in statements.
  // MUST Be in this order - add new commands to the end of the list.

  SP_KEYWORDS_EXTRA: Array[0..252] of aString =
    ('SPECTRUM ', 'PLAY ', 'AT ', 'TAB ', 'LINE ', ' THEN ', ' TO ', ' STEP ',
     'DEF ', 'CAT ', ' FORMAT ', 'MOVE ', 'ERASE ', 'OPEN ', 'CLOSE ', 'MERGE ', 'BEEP ',
     'CIRCLE ', 'INK ', 'PAPER ', 'INVERSE ', 'OUT ', 'STOP ', 'READ ', ' DATA ',
     'RESTORE ', 'NEW ', 'CONTINUE ', 'DIM ', 'REM ', 'FOR ', 'GO ', ' s** ', 'INPUT ',
     'LOAD ', 'LIST ', 'LET ', ' PAUSE ', 'NEXT ', 'POKE ', 'TEXT ', 'PLOT ', 'RUN ',
     'SAVE ', 'RANDOMIZE ', 'IF ', 'CLS ', 'DRAW ', 'CLEAR ', 'RETURN ', 'COPY ',
     'ELLIPSE ', 'CURVE ', 'INC ', 'DEC ', 'SWAP ', ' PALETTE ', 'DO ', 'WHILE ', 'UNTIL ',
     ' LOOP ', 'EXIT ', 'QUIT ', 'SCREEN ', 'LOCK ', 'UNLOCK ', 'UPDATE ', 'WINDOW ', 'SIZE ',
     'FRONT ', 'BACK ', 'SHOW ', 'HIDE ', 'GRAB ', 'PUT ', ' TRANSPARENT ', 'TRANS ', 'DPOKE ',
     'QPOKE ', 'OVER ', 'SCROLL ', 'ROLL ', 'ON ', 'EVERY ', 'OFF', 'ERROR ', 'YIELD', 'FULL ',
     'FILL ', 'RECTANGLE ', 'POLYGON ', 'DEGREES', 'RADIANS', 'RECOVER', 'FONT ', 'COLOUR',
     'MONO', ' BANK ', 'WAIT ', 'STREAM ', 'WRITE ','SEEK ', 'LABEL ', 'SETDIR ', 'MOUSEDOWN',
     'MOUSEUP', 'MOUSEMOVE', 'KEYDOWN', 'KEYUP', 'DEFAULT', 'STACK ', 'PUSH ', 'POP ', 'EXECUTE ',
     ' ROTATE ', 'FACE ', ' ASCII ', ' SAMPLE ', ' RATE ', ' VOLUME ', ' PAN ', ' BITS ',
     ' CHANNEL ', ' STEREO', ' RESUME', 'MUSIC ', ' ELSE ', 'END IF', 'END PROC', 'END STRUCT',
     ' PROC ', 'STRUCT ', 'DEF PROC ', 'DEF FN ', 'DEF STRUCT ', 'GLOBAL ', ' PROTECT ',
     ' UNPROTECT ', 'EXIT PROC ', 'REF ', 'POKE$ ', 'PRINT ', 'SCALE ', 'SPRITE ', ' ADDFRAME ',
     ' INSFRAME ', ' DELFRAME ', ' CW ', ' CCW ', 'WHEELUP', 'WHEELDOWN', 'GRAPHIC ', ' FLIP ',
     ' MIRROR ', ' REMAP ', ' DITHER ', 'FPOKE ', 'RENUMBER ', 'DELETE ', 'LAUNCH ', 'THREAD ',
     'PRIORITY ', 'PACKAGE ', ' a** ', 'ASSIGN ', ' ALL ', 'MAKEDIR ', 'RENAME ', 'CONST ',
     'CD ', 'TILEMAP ', ' SET ', ' VAR ', 'CURSOR', 'EACH ', 'MENU ', 'MOUSE ', 'DEBUG ', 'FPS ',
     ' BASE ', 'OPTION ', 'SETNUB ', 'SETCPU ', 'MULTIPLOT ', 'PROJECT3D ', 'TRANSFORM3D ',
     'TRANSFORM2D ', 'RAINBOW ', 'LOCAL ', 'CENTRE ', 'KEYBOARD ', 'ORIGIN ', 'CLIP ', ' CLONE ',
     'SHOWGUIDE ', 'HELP ', 'BORDER ', 'CASE ', 'WHEN ', 'OTHERWISE ', 'END CASE', 'INCLUDE ',
     'HALT', 'SORT ', 'KEY ', 'MAT ', 'ZER', 'IDN', 'CON', 'INV ', 'TRN ', 'ANIM ', 'FRAME ',
     'COLLIDE ', 'WRAP ', 'ZONE ', 'USING ', 'SPLIT ', ' BPP ', ' ALPHA ', ' DEPTH ', 'UNDIM ',
     'BOLD ', 'ITALIC ', 'FILTER ', 'INSERT ', 'MENUITEM ', 'MEMWRT ', 'MEMWRTD ', 'MEMWRTQ ',
     'MEMWRT$ ', 'REPEAT', 'PARTICLE ', 'FRICTION ', 'GRAVITY ', 'FORCE ', 'INSTALL', 'MEMWRTF ',
     'PRESS', 'TURNS', 'GRADIANS', 'EGA', 'CGA', 'ADDCTRL', 'CTRL', 'PROP$ ', 'OLD', ' ASYNC',
     'COMPILE ', 'APPLEHGR', 'APPLELGR', 'CPC', 'ENUM ');

  // Constants used to quickly identify keywords when in token form. Each keyword listed
  // above has a corresponding constant, which must be SP_KEYWORD_BASE + (Index of Keyword above).

  SP_KEYWORD_BASE           = 1000;

  SP_KW_SPECTRUM            = 1000;
  SP_KW_PLAY                = 1001;
  SP_KW_AT                  = 1002;
  SP_KW_TAB                 = 1003;
  SP_KW_LINE                = 1004;
  SP_KW_THEN                = 1005;
  SP_KW_TO                  = 1006;
  SP_KW_STEP                = 1007;
  SP_KW_DEF                 = 1008;
  SP_KW_CAT                 = 1009;
  SP_KW_FORMAT              = 1010;
  SP_KW_MOVE                = 1011;
  SP_KW_ERASE               = 1012;
  SP_KW_OPEN                = 1013;
  SP_KW_CLOSE               = 1014;
  SP_KW_MERGE               = 1015;
  SP_KW_BEEP                = 1016;
  SP_KW_CIRCLE              = 1017;
  SP_KW_INK                 = 1018;
  SP_KW_PAPER               = 1019;
  SP_KW_INVERSE             = 1020;
  SP_KW_OUT                 = 1021;
  SP_KW_STOP                = 1022;
  SP_KW_READ                = 1023;
  SP_KW_DATA                = 1024;
  SP_KW_RESTORE             = 1025;
  SP_KW_NEW                 = 1026;
  SP_KW_CONTINUE            = 1027;
  SP_KW_DIM                 = 1028;
  SP_KW_REM                 = 1029;
  SP_KW_FOR                 = 1030;
  SP_KW_GO                  = 1031;
  SP_KW_SUB                 = 1032;
  SP_KW_INPUT               = 1033;
  SP_KW_LOAD                = 1034;
  SP_KW_LIST                = 1035;
  SP_KW_LET                 = 1036;
  SP_KW_PAUSE               = 1037;
  SP_KW_NEXT                = 1038;
  SP_KW_POKE                = 1039;
  SP_KW_TEXT                = 1040;
  SP_KW_PLOT                = 1041;
  SP_KW_RUN                 = 1042;
  SP_KW_SAVE                = 1043;
  SP_KW_RANDOMIZE           = 1044;
  SP_KW_IF                  = 1045;
  SP_KW_CLS                 = 1046;
  SP_KW_DRAW                = 1047;
  SP_KW_CLEAR               = 1048;
  SP_KW_RETURN              = 1049;
  SP_KW_COPY                = 1050;
  SP_KW_ELLIPSE             = 1051;
  SP_KW_CURVE               = 1052;
  SP_KW_INC                 = 1053;
  SP_KW_DEC                 = 1054;
  SP_KW_SWAP                = 1055;
  SP_KW_PALETTE             = 1056;
  SP_KW_DO                  = 1057;
  SP_KW_WHILE               = 1058;
  SP_KW_UNTIL               = 1059;
  SP_KW_LOOP                = 1060;
  SP_KW_EXIT                = 1061;
  SP_KW_QUIT                = 1062;
  SP_KW_SCREEN              = 1063;
  SP_KW_LOCK                = 1064;
  SP_KW_UNLOCK              = 1065;
  SP_KW_UPDATE              = 1066;
  SP_KW_WINDOW              = 1067;
  SP_KW_SIZE                = 1068;
  SP_KW_FRONT               = 1069;
  SP_KW_BACK                = 1070;
  SP_KW_SHOW                = 1071;
  SP_KW_HIDE                = 1072;
  SP_KW_GRAB                = 1073;
  SP_KW_PUT                 = 1074;
  SP_KW_TRANSPARENT         = 1075;
  SP_KW_TRANS               = 1076;
  SP_KW_DPOKE               = 1077;
  SP_KW_QPOKE               = 1078;
  SP_KW_OVER                = 1079;
  SP_KW_SCROLL              = 1080;
  SP_KW_ROLL                = 1081;
  SP_KW_ON                  = 1082;
  SP_KW_EVERY               = 1083;
  SP_KW_OFF                 = 1084;
  SP_KW_ERROR               = 1085;
  SP_KW_YIELD               = 1086;
  SP_KW_FULL                = 1087;
  SP_KW_FILL                = 1088;
  SP_KW_RECTANGLE           = 1089;
  SP_KW_POLYGON             = 1090;
  SP_KW_DEGREES             = 1091;
  SP_KW_RADIANS             = 1092;
  SP_KW_RECOVER             = 1093;
  SP_KW_FONT                = 1094;
  SP_KW_COLOUR              = 1095;
  SP_KW_MONO                = 1096;
  SP_KW_BANK                = 1097;
  SP_KW_WAIT                = 1098;
  SP_KW_STREAM              = 1099;
  SP_KW_WRITE               = 1100;
  SP_KW_SEEK                = 1101;
  SP_KW_LABEL               = 1102;
  SP_KW_SETDIR              = 1103;
  SP_KW_MOUSEDOWN           = 1104;
  SP_KW_MOUSEUP             = 1105;
  SP_KW_MOUSEMOVE           = 1106;
  SP_KW_KEYDOWN             = 1107;
  SP_KW_KEYUP               = 1108;
  SP_KW_DEFAULT             = 1109;
  SP_KW_STACK               = 1110;
  SP_KW_PUSH                = 1111;
  SP_KW_POP                 = 1112;
  SP_KW_EXECUTE             = 1113;
  SP_KW_ROTATE              = 1114;
  SP_KW_FACE                = 1115;
  SP_KW_ASCII               = 1116;
  SP_KW_SAMPLE              = 1117;
  SP_KW_RATE                = 1118;
  SP_KW_VOLUME              = 1119;
  SP_KW_PAN                 = 1120;
  SP_KW_BITS                = 1121;
  SP_KW_CHANNEL             = 1122;
  SP_KW_STEREO              = 1123;
  SP_KW_RESUME              = 1124;
  SP_KW_MUSIC               = 1125;
  SP_KW_ELSE                = 1126;
  SP_KW_ENDIF               = 1127;
  SP_KW_ENDPROC             = 1128;
  SP_KW_ENDSTRUCT           = 1129;
  SP_KW_PROC                = 1130;
  SP_KW_STRUCT              = 1131;
  SP_KW_DEF_PROC            = 1132;
  SP_KW_DEF_FN              = 1133;
  SP_KW_DEF_STRUCT          = 1134;
  SP_KW_GLOBAL              = 1135;
  SP_KW_PROTECT             = 1136;
  SP_KW_DEPROTECT           = 1137;
  SP_KW_EXIT_PROC           = 1138;
  SP_KW_REF                 = 1139;
  SP_KW_POKES               = 1140;
  SP_KW_PRINT               = 1141;
  SP_KW_SCALE               = 1142;
  SP_KW_SPRITE              = 1143;
  SP_KW_ADDFRAME            = 1144;
  SP_KW_INSFRAME            = 1145;
  SP_KW_DELFRAME            = 1146;
  SP_KW_CW                  = 1147;
  SP_KW_CCW                 = 1148;
  SP_KW_WHEELUP             = 1149;
  SP_KW_WHEELDOWN           = 1150;
  SP_KW_GRAPHIC             = 1151;
  SP_KW_FLIP                = 1152;
  SP_KW_MIRROR              = 1153;
  SP_KW_REMAP               = 1154;
  SP_KW_DITHER              = 1155;
  SP_KW_FPOKE               = 1156;
  SP_KW_RENUMBER            = 1157;
  SP_KW_DELETE              = 1158;
  SP_KW_LAUNCH              = 1159;
  SP_KW_THREAD              = 1160;
  SP_KW_PRIORITY            = 1161;
  SP_KW_PACKAGE             = 1162;
  SP_KW_ADD                 = 1163;
  SP_KW_ASSIGN              = 1164;
  SP_KW_ALL                 = 1165;
  SP_KW_MAKEDIR             = 1166;
  SP_KW_RENAME              = 1167;
  SP_KW_CONST               = 1168;
  SP_KW_CD                  = 1169;
  SP_KW_TILEMAP             = 1170;
  SP_KW_SET                 = 1171;
  SP_KW_VAR                 = 1172;
  SP_KW_CURSOR              = 1173;
  SP_KW_EACH                = 1174;
  SP_KW_MENU                = 1175;
  SP_KW_MOUSE               = 1176;
  SP_KW_DEBUG               = 1177;
  SP_KW_FPS                 = 1178;
  SP_KW_BASE                = 1179;
  SP_KW_OPTION              = 1180;
  SP_KW_SETNUB              = 1181;
  SP_KW_SETCPU              = 1182;
  SP_KW_MULTIPLOT           = 1183;
  SP_KW_PROJECT3D           = 1184;
  SP_KW_TRANSFORM3D         = 1185;
  SP_KW_TRANSFORM2D         = 1186;
  SP_KW_RAINBOW             = 1187;
  SP_KW_LOCAL               = 1188;
  SP_KW_CENTRE              = 1189;
  SP_KW_KEYBOARD            = 1190;
  SP_KW_ORIGIN              = 1191;
  SP_KW_CLIP                = 1192;
  SP_KW_CLONE               = 1193;
  SP_KW_SHOWGUIDE           = 1194;
  SP_KW_HELP                = 1195;
  SP_KW_BORDER              = 1196;
  SP_KW_CASE                = 1197;
  SP_KW_WHEN                = 1198;
  SP_KW_OTHERWISE           = 1199;
  SP_KW_END_CASE            = 1200;
  SP_KW_INCLUDE             = 1201;
  SP_KW_HALT                = 1202;
  SP_KW_SORT                = 1203;
  SP_KW_KEY                 = 1204;
  SP_KW_MAT                 = 1205;
  SP_KW_MAT_ZER             = 1206;
  SP_KW_MAT_IDN             = 1207;
  SP_KW_MAT_CON             = 1208;
  SP_KW_MAT_INV             = 1209;
  SP_KW_MAT_TRN             = 1210;
  SP_KW_ANIM                = 1211;
  SP_KW_FRAME               = 1212;
  SP_KW_COLLIDE             = 1213;
  SP_KW_WRAP                = 1214;
  SP_KW_ZONE                = 1215;
  SP_KW_USING               = 1216;
  SP_KW_SPLIT               = 1217;
  SP_KW_BPP                 = 1218;
  SP_KW_ALPHA               = 1219;
  SP_KW_DEPTH               = 1220;
  SP_KW_UNDIM               = 1221;
  SP_KW_BOLD                = 1222;
  SP_KW_ITALIC              = 1223;
  SP_KW_FILTER              = 1224;
  SP_KW_INSERT              = 1225;
  SP_KW_MENUITEM            = 1226;
  SP_KW_MEMWRITE            = 1227;
  SP_KW_MEMWRITED           = 1228;
  SP_KW_MEMWRITEQ           = 1229;
  SP_KW_MEMWRITES           = 1230;
  SP_KW_REPEAT              = 1231;
  SP_KW_PARTICLE            = 1232;
  SP_KW_FRICTION            = 1233;
  SP_KW_GRAVITY             = 1234;
  SP_KW_FORCE               = 1235;
  SP_KW_INSTALL             = 1236;
  SP_KW_MEMWRITEF           = 1237;
  SP_KW_PRESS               = 1238;
  SP_KW_TURNS               = 1239;
  SP_KW_GRADIANS            = 1240;
  SP_KW_EGA                 = 1241;
  SP_KW_CGA                 = 1242;
  SP_KW_ADDCTRL             = 1243;
  SP_KW_CTRL                = 1244;
  SP_KW_PROPS               = 1245;
  SP_KW_OLD                 = 1246;
  SP_KW_ASYNC               = 1247;
  SP_KW_COMPILE             = 1248;
  SP_KW_APPLEHGR            = 1249;
  SP_KW_APPLELGR            = 1250;
  SP_KW_CPC                 = 1251;
  SP_KW_ENUM                = 1252;


  // These are meta-commands; they do not appear in listings, and are used during
  // execution only, having been inserted by the pre-processor.

  SP_KW_PR_INK              = 4051;
  SP_KW_PR_PAPER            = 4052;
  SP_KW_PR_INVERSE          = 4053;
  SP_KW_PR_TAB              = 4054;
  SP_KW_PR_AT               = 4055;
  SP_KW_PR_MOVE             = 4056;
  SP_KW_GOTO                = 4057;
  SP_KW_GOSUB               = 4058;
  SP_KW_PALSHIFT            = 4059;
  SP_KW_READ_ASSIGN         = 4060;
  SP_KW_DRAWTO              = 4061;
  SP_KW_SCR_LOCK            = 4062;
  SP_KW_SCR_UNLOCK          = 4063;
  SP_KW_SCR_UPDATE          = 4064;
  SP_KW_SCR_RES             = 4065;
  SP_KW_WIN_NEW             = 4066;
  SP_KW_WIN_DEL             = 4067;
  SP_KW_WIN_MOVE            = 4068;
  SP_KW_WIN_SIZE            = 4069;
  SP_KW_WIN_FRONT           = 4070;
  SP_KW_WIN_BACK            = 4071;
  SP_KW_WIN_SHOW            = 4072;
  SP_KW_WIN_HIDE            = 4073;
  SP_KW_SCR_GRAB            = 4074;
  SP_KW_WIN_GRAB            = 4075;
  SP_KW_PAL_HSV             = 4076;
  SP_KW_WIN_PUT             = 4077;
  SP_KW_PR_OVER             = 4078;
  SP_KW_WIN_SCROLL          = 4079;
  SP_KW_WIN_ROLL            = 4080;
  SP_KW_ONERR               = 4081;
  SP_KW_CLEAR_VAR           = 4082;
  SP_KW_CLEAR_ERR           = 4083;
  SP_KW_ON_ERR              = 4084;
  SP_KW_DBG                 = 4085;
  SP_KW_ON_ERR_OFF          = 4086;
  SP_KW_PR_TRANSPARENT      = 4087;
  SP_KW_FULLSCREEN          = 4088;
  SP_KW_WINDOWED            = 4089;
  SP_KW_POLYFILL            = 4090;
  SP_KW_POLYLINE            = 4091;
  SP_KW_RECTFILL            = 4092;
  SP_KW_CIRCLEFILL          = 4093;
  SP_KW_ELLIPSEFILL         = 4094;
  SP_KW_SCRCOPY             = 4095;
  SP_KW_FONT_NEW            = 4096;
  SP_KW_FONT_TRANS          = 4097;
  SP_KW_FONT_ERASE          = 4098;
  SP_KW_LOAD_BANK           = 4099;
  SP_KW_SAVE_BANK           = 4100;
  SP_KW_INCRANGE            = 4101;
  SP_KW_DECRANGE            = 4102;
  SP_KW_BANK_SIZE           = 4103;
  SP_KW_BANK_ERASE          = 4104;
  SP_KW_BANK_COPY           = 4105;
  SP_KW_STREAM_NEW          = 4106;
  SP_KW_STREAM_WRITE        = 4107;
  SP_KW_STREAM_READ         = 4108;
  SP_KW_STREAM_CLOSE        = 4109;
  SP_KW_STREAM_SEEK         = 4110;
  SP_KW_MOUSEDOWN_OFF       = 4111;
  SP_KW_MOUSEUP_OFF         = 4112;
  SP_KW_MOUSEMOVE_OFF       = 4113;
  SP_KW_KEYDOWN_OFF         = 4114;
  SP_KW_KEYUP_OFF           = 4115;
  SP_KW_ON_MOUSEDOWN        = 4116;
  SP_KW_ON_MOUSEUP          = 4117;
  SP_KW_ON_MOUSEMOVE        = 4118;
  SP_KW_ON_KEYDOWN          = 4119;
  SP_KW_ON_KEYUP            = 4120;
  SP_KW_PAL_LOAD            = 4121;
  SP_KW_PAL_SAVE            = 4122;
  SP_KW_PAL_DEFAULT         = 4123;
  SP_KW_STACK_NEW           = 4124;
  SP_KW_STACK_PUSH          = 4125;
  SP_KW_STACK_POP           = 4126;
  SP_KW_DRMOVETO            = 4127;
  SP_KW_ROTATETO            = 4128;
  SP_KW_DRAWTURTLE          = 4129;
  SP_KW_DRMOVEXY            = 4130;
  SP_KW_SAVEASCII           = 4131;
  SP_KW_SAMPLE_LOAD         = 4132;
  SP_KW_SAMPLE_PLAY         = 4133;
  SP_KW_SAMPLE_NEW          = 4134;
  SP_KW_SAMPLE_RATE         = 4135;
  SP_KW_SAMPLE_DEPTH        = 4136;
  SP_KW_SAMPLE_STEREO       = 4137;
  SP_KW_SAMPLE_VOLUME       = 4138;
  SP_KW_SAMPLE_PAN          = 4139;
  SP_KW_SAMPLE_ERASE        = 4140;
  SP_KW_CHANNEL_PAUSE       = 4141;
  SP_KW_CHANNEL_STOP        = 4142;
  SP_KW_CHANNEL_VOLUME      = 4143;
  SP_KW_CHANNEL_PAN         = 4144;
  SP_KW_CHANNEL_RESUME      = 4145;
  SP_KW_CHANNEL_SEEK        = 4146;
  SP_KW_CHANNEL_RATE_VAL    = 4147;
  SP_KW_MUSIC_PLAY          = 4148;
  SP_KW_MUSIC_PAUSE         = 4149;
  SP_KW_MUSIC_STOP          = 4150;
  SP_KW_MUSIC_VOLUME        = 4151;
  SP_KW_MUSIC_RESUME        = 4152;
  SP_KW_MUSIC_SEEK          = 4153;
  SP_KW_BANK_COPY_EX        = 4154;
  SP_KW_BANK_PROTECT        = 4155;
  SP_KW_BANK_DEPROTECT      = 4156;
  SP_KW_BANK_DEFAULT        = 4157;
  SP_KW_WIN_PUT_EX          = 4158;
  SP_KW_NEW_SPRITE          = 4159;
  SP_KW_SPRITE_ADDFR        = 4160;
  SP_KW_SPRITE_SHOW         = 4161;
  SP_KW_SPRITE_HIDE         = 4162;
  SP_KW_SPRITE_MOVE         = 4163;
  SP_KW_SPRITE_MOVED        = 4164;
  SP_KW_SPRITE_MOVE_T       = 4165;
  SP_KW_SPRITE_MOVED_T      = 4166;
  SP_KW_SPRITE_MOVE_S       = 4167;
  SP_KW_SPRITE_MOVED_S      = 4168;
  SP_KW_SPRITE_MOVE_WIN     = 4169;
  SP_KW_SPRITE_STOP         = 4170;
  SP_KW_SPRITE_ROT          = 4171;
  SP_KW_SPRITE_ROT_TO       = 4172;
  SP_KW_SPRITE_ROT_T        = 4173;
  SP_KW_SPRITE_ROT_TO_T     = 4174;
  SP_KW_SPRITE_SCALE        = 4175;
  SP_KW_SPRITE_SCALE_T      = 4176;
  SP_KW_SPRITE_ERASE        = 4177;
  SP_KW_SPRITE_CLEAR        = 4178;
  SP_KW_WHEELUP_OFF         = 4179;
  SP_KW_WHEELDOWN_OFF       = 4180;
  SP_KW_ON_WHEELUP          = 4181;
  SP_KW_ON_WHEELDOWN        = 4182;
  SP_KW_GFX_NEW_SIZE        = 4183;
  SP_KW_GFX_NEW_LOAD        = 4184;
  SP_KW_GFX_NEW_GFXS        = 4185;
  SP_KW_GFX_LOAD            = 4186;
  SP_KW_GFX_GRAB            = 4187;
  SP_KW_GFX_PUT             = 4188;
  SP_KW_GFX_PUT_EX          = 4189;
  SP_KW_GFX_ROTATE          = 4190;
  SP_KW_GFX_SCALE           = 4191;
  SP_KW_GFX_FLIP            = 4192;
  SP_KW_GFX_MIRROR          = 4193;
  SP_KW_GFX_ERASE           = 4194;
  SP_KW_GFX_TRANSPARENT     = 4195;
  SP_KW_GFX_REMAP           = 4196;
  SP_KW_GFX_PAL_DEFAULT     = 4197;
  SP_KW_GFX_PAL_HSV         = 4198;
  SP_KW_GFX_PALETTE         = 4199;
  SP_KW_PAL_COPY            = 4200;
  SP_KW_WINDOW_GFX          = 4201;
  SP_KW_READLINE            = 4202;
  SP_KW_ERASE_LINES         = 4203;
  SP_KW_LIST_LINES          = 4204;
  SP_KW_PACK_NEW            = 4205;
  SP_KW_PACK_OPEN           = 4206;
  SP_KW_PACK_CLOSE          = 4207;
  SP_KW_PACK_ADD            = 4208;
  SP_KW_MOVE_FILES          = 4209;
  SP_KW_PACK_PROTECT        = 4210;
  SP_KW_PACK_UNPROTECT      = 4211;
  SP_KW_DATA_LOAD           = 4212;
  SP_KW_DATA_SAVE           = 4213;
  SP_KW_MERGE_LINES         = 4214;
  SP_KW_GFX_ROLL            = 4215;
  SP_KW_GFX_SCROLL          = 4216;
  SP_KW_TILEMAP_NEW         = 4217;
  SP_KW_TILEMAP_DRAW        = 4218;
  SP_KW_TILEMAP_SET         = 4219;
  SP_KW_TILEMAP_GRAPHIC     = 4220;
  SP_KW_TILEMAP_CLEAR       = 4221;
  SP_KW_FILLTEX             = 4222;
  SP_KW_SAVE_BANK_DATA      = 4223;
  SP_KW_LIST_WINDOW         = 4224;
  SP_KW_LIST_BANK           = 4225;
  SP_KW_LIST_VAR            = 4226;
  SP_KW_LIST_ARRAY          = 4227;
  SP_KW_LIST_ASSIGN         = 4228;
  SP_KW_LIST_BANK_EX        = 4229;
  SP_KW_BANK_ERASE_ALL      = 4230;
  SP_KW_LIST_STRUCT         = 4231;
  SP_KW_STRUCT_ERASE        = 4232;
  SP_KW_INPUT_NUM           = 4233;
  SP_KW_INPUT_STR           = 4234;
  SP_KW_INIT_INPUT          = 4235;
  SP_KW_INPUT_FORMAT        = 4236;
  SP_KW_PR_CURSOR           = 4237;
  SP_KW_INPUT_FINAL         = 4238;
  SP_KW_INPUT_ERROR         = 4239;
  SP_KW_FOR_EACH            = 4240;
  SP_KW_MENU_NEW            = 4241;
  SP_KW_MENU_INSITEM        = 4242;
  SP_KW_MENU_DELITEM        = 4243;
  SP_KW_MENU_ADDSUB         = 4244;
  SP_KW_MENU_DELSUB         = 4245;
  SP_KW_MENU_ERASE          = 4246;
  SP_KW_MOUSE_SHOW          = 4247;
  SP_KW_MOUSE_HIDE          = 4248;
  SP_KW_MOUSE_GRAPHIC       = 4249;
  SP_KW_MOUSE_GFXS          = 4250;
  SP_KW_MOUSE_DEFAULT       = 4251;
  SP_KW_PR_CENTRE           = 4252;
  SP_KW_WIN_ORIGIN          = 4253;
  SP_KW_GFX_ORIGIN          = 4254;
  SP_KW_WIN_ORG_NO_EXT      = 4255;
  SP_KW_GFX_ORG_NO_EXT      = 4256;
  SP_KW_WIN_ORG_OFF         = 4257;
  SP_KW_GFX_ORG_OFF         = 4258;
  SP_KW_PR_CLIP             = 4259;
  SP_KW_ORG_NO_EXT          = 4260;
  SP_KW_ORG_OFF             = 4261;
  SP_KW_WIN_CLIP            = 4262;
  SP_KW_GFX_CLIP            = 4263;
  SP_KW_WIN_CLIP_OFF        = 4264;
  SP_KW_GFX_CLIP_OFF        = 4265;
  SP_KW_SPRITE_CLONE        = 4266;
  SP_KW_SPRITE_CLONE_ERASE  = 4267;
  SP_KW_SPRITE_CLONE_MOVE   = 4268;
  SP_KW_DRAW_CTO            = 4269;
  SP_KW_OUT_SCREEN          = 4270;
  SP_KW_OUT_VAR             = 4271;
  SP_KW_OUT_STREAM          = 4272;
  SP_KW_PR_OUT_SCREEN       = 4273;
  SP_KW_PR_OUT_VAR          = 4274;
  SP_KW_PR_OUT_STREAM       = 4275;
  SP_KW_CLIP_OFF            = 4276;
  SP_KW_PR_CLIP_OFF         = 4277;
  SP_KW_FOR_EACH_RANGE      = 4278;
  SP_KW_WIN_MERGE           = 4279;
  SP_KW_WIN_MERGEALL        = 4280;
  SP_KW_AUTODIM             = 4281;
  SP_KW_WHEN_IN             = 4282;
  SP_KW_KEY_NUM             = 4283;
  SP_KW_KEY_STR             = 4284;
  SP_KW_KEY_CLEAR           = 4285;
  SP_KW_KEY_CLEAR_ALL       = 4286;
  SP_KW_DYNAMIC_DIM         = 4287;
  SP_KW_MAT_ADD             = 4288;
  SP_KW_MAT_SUB             = 4289;
  SP_KW_MAT_PROD            = 4290;
  SP_KW_MAT_SCALE           = 4291;
  SP_KW_MAT_IDN_PARAM       = 4292;
  SP_KW_MAT_CON_PARAM       = 4293;
  SP_KW_PR_SCALE            = 4294;
  SP_KW_SPRITE_POINT        = 4295;
  SP_KW_SPRITE_SET_ANIM     = 4296;
  SP_KW_SPRITE_ANIM_STOP    = 4297;
  SP_KW_SPRITE_FRAME        = 4298;
  SP_KW_SPRITE_MIRROR       = 4299;
  SP_KW_SPRITE_FLIP         = 4300;
  SP_KW_COLLIDE_OFF         = 4301;
  SP_KW_ON_COLLIDE          = 4302;
  SP_KW_ON_COLLIDE_OFF      = 4303;
  SP_KW_SPRITE_COLLIDE_CLEAR= 4304;
  SP_KW_NEW_BANK            = 4305;
  SP_KW_SPRITE_PUT          = 4306;
  SP_KW_SPRITE_OVER         = 4307;
  SP_KW_ZONE_NEW            = 4308;
  SP_KW_ZONE_ERASE          = 4309;
  SP_KW_LIST_ZONE           = 4310;
  SP_KW_ZONE_MOVE           = 4311;
  SP_KW_ZONE_MOVETO         = 4312;
  SP_KW_ZONE_UPDATE         = 4313;
  SP_KW_ZONE_NEW_B          = 4314;
  SP_KW_ZONE_UPDATE_B       = 4315;
  SP_KW_RECTANGLE2          = 4316;
  SP_KW_RECTFILL2           = 4317;
  SP_KW_PR_USING            = 4318;
  SP_KW_DIM_SPLIT           = 4319;
  SP_KW_PR_CENTRE_OFF       = 4320;
  SP_KW_WIN_TRANS           = 4321;
  SP_KW_WIN_ALPHA           = 4322;
  SP_KW_WIN_DEPTH           = 4323;
  SP_KW_ADRAWTO             = 4324;
  SP_KW_ADRAWTURTLE         = 4325;
  SP_KW_ACIRCLEFILL         = 4326;
  SP_KW_AELLIPSEFILL        = 4327;
  SP_KW_AFILLTEX            = 4328;
  SP_KW_ARECTFILL           = 4329;
  SP_KW_ARECTANGLE2         = 4330;
  SP_KW_ARECTFILL2          = 4331;
  SP_KW_APOLYLINE           = 4332;
  SP_KW_APOLYFILL           = 4333;
  SP_KW_ACIRCLE             = 4334;
  SP_KW_APLOT               = 4335;
  SP_KW_ADRAW               = 4336;
  SP_KW_AELLIPSE            = 4337;
  SP_KW_ACURVE              = 4338;
  SP_KW_AFILL               = 4339;
  SP_KW_ARECTANGLE          = 4340;
  SP_KW_APOLYGON            = 4341;
  SP_KW_AMULTIPLOT          = 4342;
  SP_KW_ADRAW_CTO           = 4343;
  SP_KW_APRINT              = 4344;
  SP_KW_ATEXT               = 4345;
  SP_KW_DO_COUNT            = 4346;
  SP_KW_SPRITE_COLL_CLR_ID  = 4347;
  SP_KW_CURVE_EX            = 4348;
  SP_KW_ACURVE_EX           = 4349;
  SP_KW_FILTER_STR          = 4350;
  SP_KW_FILTER_NUM_R        = 4351;
  SP_KW_FILTER_NUM          = 4352;
  SP_KW_GOTOC               = 4353;
  SP_KW_GOSUBC              = 4354;
  SP_KW_MENU_ADD_ITEM       = 4355;
  SP_KW_MENU_SHOW           = 4356;
  SP_KW_MENU_HIDE           = 4357;
  SP_KW_MENU_ERASE_ALL      = 4358;
  SP_KW_MENU_ATTR           = 4359;
  SP_KW_MENUITEM_ATTR       = 4360;
  SP_KW_MENU_FONT           = 4361;
  SP_KW_MENU_SHOW_OFF       = 4362;
  SP_KW_MENU_HIDE_OFF       = 4363;
  SP_KW_MENUITEM_OFF        = 4364;
  SP_KW_ON_MENU_SHOW        = 4365;
  SP_KW_ON_MENU_HIDE        = 4366;
  SP_KW_ON_MENUITEM         = 4367;
  SP_KW_CLS_ALPHA           = 4368;
  SP_KW_IMPLICIT_LET        = 4369;
  SP_KW_MULTIDRAW           = 4370;
  SP_KW_MULTIDRAW_TO        = 4371;
  SP_KW_AMULTIDRAW          = 4372;
  SP_KW_AMULTIDRAW_TO       = 4373;
  SP_KW_INPUT_ERR_RPT       = 4374;
  SP_KW_MAT_INTERP          = 4375;
  SP_KW_GFX_FLIP_STR        = 4376;
  SP_KW_GFX_MIRROR_STR      = 4377;
  SP_KW_WINDOW_FLIP         = 4378;
  SP_KW_WINDOW_MIRROR       = 4379;
  SP_KW_PR_ITALIC           = 4380;
  SP_KW_PR_BOLD             = 4381;
  SP_KW_SPRITE_FRONT        = 4382;
  SP_KW_SPRITE_BACK         = 4383;
  SP_KW_SPRITE_FRONT_ADD    = 4384;
  SP_KW_SPRITE_BACK_DEC     = 4385;
  SP_KW_CHANNEL_RATE_STR    = 4386;
  SP_KW_GFX_SCALE_XY        = 4387;
  SP_KW_GFX_SCALE_TO        = 4388;
  SP_KW_SCREEN_SAVE         = 4389;
  SP_KW_GRAPHIC_SAVE        = 4390;
  SP_KW_WAIT_KEY            = 4391;
  SP_KW_WAIT_KEY_PRESS      = 4392;
  SP_KW_PAL_EGA             = 4393;
  SP_KW_PAL_CGA             = 4394;
  SP_KW_WINDOW_ADDCTRL      = 4395;
  SP_KW_ORIGIN_FLIP         = 4396;
  SP_KW_WIN_ORG_FLIP        = 4397;
  SP_KW_PLAY_STOP           = 4398;
  SP_KW_MOUSE_TO            = 4399;
  SP_KW_PAL_APPLELGR        = 4400;
  SP_KW_PAL_APPLEHGR        = 4401;
  SP_KW_PAL_CPC             = 4402;
  SP_KW_STREAM_READLN       = 4403;
  SP_KW_ARECTANGLE_TO       = 4404;
  SP_KW_ARECTFILL_TO        = 4405;
  SP_KW_RECTANGLE_TO        = 4406;
  SP_KW_RECTFILL_TO         = 4407;
  SP_KW_WAIT_KEY_UP         = 4408;
  SP_KW_FOR_EACH_STRING     = 4409;
  SP_KW_ENUM_BASE           = 4410;

  // Names of the above meta-keywords - for use by the DEBUG command.

  SP_Keyword_Names: Array[0..359] of aString =
    ('PR INK', 'PR PAPER', 'PR INVERSE', 'PR TAB', 'PR AT', 'PR MOVE', 'GOTO', 'GOSUB', 'PALSHIFT',
     'READ ASSIGN', 'DRAWTO', 'SCR LOCK', 'SCR UNLOCK', 'SCR UPDATE', 'SCR RES', 'WIN NEW', 'WIN DEL',
     'WIN MOVE', 'WIN SIZE', 'WIN FRONT', 'WIN BACK', 'WIN SHOW', 'WIN HIDE', 'SCR GRAB', 'WIN GRAB',
     'PAL HSV', 'WIN PUT', 'PR OVER', 'WIN SCROLL', 'WIN ROLL', 'ONERR', 'CLEAR VAR', 'CLEAR ERR',
     'ON ERR', 'DBG', 'ON ERR OFF', 'PR TRANSPARENT', 'FULLSCREEN', 'WINDOWED', 'POLYFILL', 'POLYLINE',
     'RECTFILL', 'CIRCLEFILL', 'ELLIPSEFILL', 'SCRCOPY', 'FONT NEW', 'FONT TRANS', 'FONT ERASE',
     'LOAD BANK', 'SAVE BANK', 'INCRANGE', 'DECRANGE', 'BANK SIZE', 'BANK ERASE', 'BANK COPY',
     'STREAM NEW', 'STREAM WRITE', 'STREAM READ', 'STREAM CLOSE', 'STREAM SEEK', 'MOUSEDOWN OFF',
     'MOUSEUP OFF', 'MOUSEMOVE OFF', 'KEYDOWN OFF', 'KEYUP OFF', 'ON MOUSEDOWN', 'ON MOUSEUP', 'ON MOUSEMOVE',
     'ON KEYDOWN', 'ON KEYUP', 'PAL LOAD', 'PAL SAVE', 'PAL DEFAULT', 'STACK NEW', 'STACK PUSH',
     'STACK POP', 'DRMOVETO', 'ROTATETO', 'DRAWTURTLE', 'DRMOVEXY', 'SAVEASCII', 'SAMPLE LOAD', 'SAMPLE PLAY',
     'SAMPLE NEW', 'SAMPLE RATE', 'SAMPLE DEPTH', 'SAMPLE STEREO', 'SAMPLE VOLUME', 'SAMPLE PAN', 'SAMPLE ERASE',
     'CHANNEL PAUSE', 'CHANNEL STOP', 'CHANNEL VOLUME', 'CHANNEL PAN', 'CHANNEL RESUME', 'CHANNEL SEEK',
     'CHANNEL RATE VALUE', 'MUSIC PLAY', 'MUSIC PAUSE', 'MUSIC STOP', 'MUSIC VOLUME', 'MUSIC RESUME', 'MUSIC SEEK',
     'BANK COPY EX', 'BANK PROTECT', 'BANK DEPROTECT', 'BANK DEFAULT', 'WIN PUT EX', 'NEW SPRITE', 'SPRITE ADDFR',
     'SPRITE SHOW', 'SPRITE HIDE', 'SPRITE MOVE', 'SPRITE MOVED', 'SPRITE MOVE T', 'SPRITE MOVED T',
     'SPRITE MOVE S', 'SPRITE MOVED S', 'SPRITE MOVE WIN', 'SPRITE STOP', 'SPRITE ROT', 'SPRITE ROT TO',
     'SPRITE ROT T', 'SPRITE ROT TO T', 'SPRITE SCALE', 'SPRITE SCALE T', 'SPRITE ERASE', 'SPRITE CLEAR',
     'WHEELUP OFF', 'WHEELDOWN OFF', 'ON WHEELUP', 'ON WHEELDOWN', 'GFX NEW SIZE', 'GFX NEW LOAD', 'GFX NEW GFXS',
     'GFX LOAD', 'GFX GRAB', 'GFX PUT', 'GFX PUT EX', 'GFX ROTATE', 'GFX SCALE', 'GFX FLIP', 'GFX MIRROR',
     'GFX ERASE', 'GFX TRANSPARENT', 'GFX REMAP', 'GFX PAL DEFAULT', 'GFX PAL HSV', 'GFX PALETTE', 'PAL COPY',
     'WINDOW GFX', 'READLINE', 'ERASE LINES', 'LIST LINES', 'PACK NEW', 'PACK OPEN', 'PACK CLOSE', 'PACK ADD',
     'MOVE FILES', 'PACK PROTECT', 'PACK UNPROTECT', 'DATA LOAD', 'DATA SAVE', 'MERGE LINES', 'GFX ROLL',
     'GFX SCROLL', 'TILEMAP NEW', 'TILEMAP DRAW', 'TILEMAP SET', 'TILEMAP GRAPHIC', 'TILEMAP CLEAR', 'FILLTEX',
     'SAVE BANK DATA', 'LIST WINDOW', 'LIST BANK', 'LIST VAR', 'LIST ARRAY', 'LIST ASSIGN', 'LIST BANK EX',
     'BANK ERASE ALL', 'LIST STRUCT', 'STRUCT ERASE', 'INPUT NUM', 'INPUT STR', 'INIT INPUT', 'INPUT FORMAT',
     'PR CURSOR', 'INPUT FINAL', 'INPUT ERROR', 'FOR EACH', 'MENU NEW', 'MENU INSITEM', 'MENU DELITEM', 'MENU ADDSUB',
     'MENU DELSUB', 'MENU ERASE', 'MOUSE SHOW', 'MOUSE HIDE', 'MOUSE GRAPHIC', 'MOUSE GFXS', 'MOUSE DEFAULT',
     'PR CENTRE', 'WIN ORIGIN', 'GFX ORIGIN', 'WIN ORG NO EXT', 'GFX ORG NO EXT', 'WIN ORG OFF', 'GFX ORG OFF',
     'PR CLIP', 'ORG NO EXT', 'ORG OFF', 'WIN CLIP', 'GFX CLIP', 'WIN CLIP OFF', 'GFX CLIP OFF', 'SPRITE CLONE',
     'SPRITE CLONE ERASE', 'SPRITE CLONE MOVE', 'DRAW CTO', 'OUT SCREEN', 'OUT VAR', 'OUT STREAM', 'PR OUT SCREEN',
     'PR OUT VAR', 'PR OUT STREAM', 'CLIP OFF', 'PR CLIP OFF', 'FOR EACH RANGE', 'WIN MERGE', 'WIN MERGEALL',
     'AUTODIM', 'WHEN IN', 'KEY NUM', 'KEY STR', 'KEY CLEAR', 'KEY CLEAR ALL', 'DYNAMIC DIM', 'MAT ADD',
     'MAT SUB', 'MAT PROD', 'MAT SCALE', 'MAT IDN PARAM', 'MAT CON PARAM', 'PR SCALE', 'SPRITE POINT',
     'SPRITE SET ANIM', 'SPRITE ANIM STOP', 'SPRITE FRAME', 'SPRITE MIRROR', 'SPRITE FLIP', 'COLLIDE OFF',
     'ON COLLIDE', 'ON COLLIDE OFF', 'SPRITE COLLIDE CLEAR', 'NEW BANK', 'SPRITE PUT', 'SPRITE OVER',
     'ZONE NEW', 'ZONE ERASE', 'LIST ZONE', 'ZONE MOVE', 'ZONE MOVE TO', 'ZONE UPDATE', 'ZONE NEW SIZE',
     'ZONE UPDATE SIZE', 'RECTANGLE_S', 'RECTFILL_S', 'PR USING', 'DIM SPLIT', 'PR CENTRE OFF', 'WIN TRANSPARENT',
     'WIN ALPHA', 'WIN DEPTH', 'A-DRAWTO', 'A-DRAW TURTLE', 'A-CIRCLE FILL', 'A-ELLIPSE FILL', 'A-TEXTURE FILL',
     'A-RECTFILL', 'A-RECTANGLE2', 'A-RECTFILL2', 'A-POLY LINE', 'A-POLY FILL', 'A-CIRCLE', 'A-PLOT', 'A_DRAW',
     'A-ELLIPSE', 'A-CURVE', 'A-FILL', 'A-RECTANGLE', 'A-PLOYGON', 'A_POLYFILL', 'A-MULTIPLOT', 'A-PRINT', 'A-TEXT',
     'DO COUNT', 'SP COLL CLR ID', 'CURVEX', 'A-CURVEX', 'FILTER_STR', 'FILTER_NUM_R', 'FILTER_NUM', 'GOTOC', 'GOSUBC',
     'MENU ADD ITEM', 'MENU SHOW', 'MENU HIDE', 'MENU ERASE ALL', 'MENU ATTR', 'MENU ITEM ATTR', 'MENU FONT',
     'MENU SHOW OFF', 'MENU HIDE OFF', 'MENUITEM OFF', 'ON MENU SHOW', 'ON MENU HIDE', 'ON MENUITEM', 'CLS ALPHA',
     'IMPLICIT LET', 'MULTIDRAW', 'MULTIDRAW TO', 'A-MULTIDRAW', 'A-MULTIDRAW TO', 'INPUT ERROR REPEAT',
     'MAT INTERP', 'FLIP GFXSTR', 'MIRROR GFXSTR', 'WINDOW FLIP', 'WINDOW MIRROR', 'PR ITALIC', 'PR BOLD',
     'SPRITE FRONT', 'SPRITE BACK', 'SPRITE FRONT ADD', 'SPRITE BACK DEC', 'CHANNEL RATE STRING', 'GFX SCALE XY',
     'GFX SCALE TO', 'SCREEN SAVE', 'GRAPHIC SAVE', 'WAIT KEY', 'WAIT KEY PRESS', 'PALETTE EGA', 'PALETTE CGA',
     'WINDOW ADD CONTROL', 'ORIGIN FLIP', 'WIN ORG FLIP', 'PLAY STOP', 'MOUSE TO ', 'PALETTE APPLE LGR',
     'PALETTE APPLE HGR', 'PALETTE CPC', 'STREAM READLN', 'A-RECTANGLE TO', 'A-RECTFILL TO', 'RECTANGLE TO',
     'RECTFILL TO', 'WAIT KEY UP', 'FOR EACH STRING', 'ENUM BASE');

  // List of Functions that are used in expressions. Again, MUST be in order.
  // Functions that take only one parameter have a space at the end of their name. All others have no spaces.

  SP_FUNCTIONS_EXTRA: Array[0..273] of aString =
    ('nRND', 'nINKEY$', 'oPI', 'nVAL$ ', 'oCODE ', 'oVAL ', 'oLEN ', 'nSIN ', 'nCOS ',
     'nTAN ', 'nASN ', 'nACS ', 'nATN ', 'oLN ', 'oEXP ', 'oINT ', 'oSQR ', 'oSGN ', 'oABS ', 'n IN ',
     'nUSR ', 'oSTR$ ','oCHR$ ', 'nPEEK ', 'oNOT ', 'o OR ', 'o AND ', 'o MOD ', 'o XOR ', 'o SHL ',
     'o SHR ', 'oFRAC ', 'oCEIL ', 'oFLOOR ', 'oMAX', 'oMIN', 'oROUND', 'oODD ', 'oEVEN ', 'oPOS',
     'oTRUNC ', 'oLEFT$', 'oRIGHT$', 'oMID$', 'oUP$ ', 'oLOW$ ', 'oREP$', 'oRED ', 'oGREEN ',
     'oBLUE ', 'nRGB ', 'oHEX$ ', 'oBIN$ ', 'nRGBf ', 'nRGBn ', 'nKEYST ', 'nHSV ', 'nRGBc ', 'oHUE ',
     'oSATURATION ', 'oVALUE ', 'nWINw', 'nWINh', 'nSCRw', 'nSCRh', 'ncWIN', 'oRGBtoINT', 'oHSVtoINT',
     'oRGBtoHSV ', 'oHSVtoRGB ', 'oTRIM$ ', 'oLTRIM$ ', 'oRTRIM$ ', 'nUDG ', 'oUDG$ ', 'nDPEEK ',
     'nQPEEK ', 'nMOUSEx', 'nMOUSEy', 'nMOUSEBTN', 'nERRORNUM', 'nERRORLINE', 'nERRORSTATEMENT',
     'oDEGTORAD ', 'oRADTODEG ', 'nFONTBANK', 'nFONTw', 'nFONTh', 'nFONTm', 'nFONTt', 'nSTREAMLEN ',
     'nSTREAMPOS ', 'nBANKLEN ', 'nGETDIR', 'nMOUSEdx', 'nMOUSEdy', 'oDCHR$ ', 'oQCHR$ ', 'oDCODE ',
     'oQCODE ', 'oTOKEN$ ', 'nHEADING', 'nDRPOSX', 'nDRPOSY', 'nCHPOS ', 'nWINOFF ', 'nCALL ', 'nPEEK$ ',
     'nLASTK', 'nSPFRADDR ', 'nSPRITEx ', 'nSPRITEy ', 'nSPRITEw ', 'nSPRITEh ', 'nSPRITEv ',
     'nSPFCOUNT ', 'nSPROT ', 'nSPSCALE ', 'nFRAMES', 'nTIME', 'oDAY$ ', 'oMONTH$ ', 'oYEAR ',
     'oHOUR ', 'oMINUTES ', 'oSECONDS ', 'oDAY ', 'oMONTH ', 'nMOUSEWHEEL', 'nGFX$ ', 'nGRGB ',
     'nGHSV ', 'nWINX ', 'nWINY ', 'nGFXw ', 'nGFXh ', 'nGFXTRANS ', 'nGPOINT ', 'nFPEEK ', 'nITEM',
     'oFCODE ', 'oFCHR$ ', 'oPOWER', 'nDIR ', 'nPOINT', 'nFN ', 'nGETTILE', 'oPOWERTWO ', 'oLOGTWO ',
     'oWORDSWAP ', 'oBYTESWAP ', 'oNYBBLESWAP ', 'nPOLAR ', 'oCLAMP ', 'oINRANGE ', 'oINSERT$ ',
     'oITEM$ ', 'oBIT ', 'oHIWORD', 'oLOWORD', 'oHIBYTE', 'oLOBYTE', 'oPOLARDIST ', 'oLPAD$ ', 'oRPAD$ ',
     'nPROCID ', 'nPROCID$ ', 'oBTSET', 'oBTCLR', 'nERROR$', 'nMENUBOX', 'nPOPLINE', 'nPOPST', 'nVOL',
     'nGETOPT ', 'nGETOPT$ ', 'nNUBMODE ', 'nNUBX ', 'nNUBY ', 'nFILEEXISTS ', 'oFPATH ', 'oFNAME ',
     'nDIREXISTS ', 'oPYTH', 'nLOGW', 'nLOGH', 'nORGX', 'nORGY', 'nPTOLX ', 'nPTOLY ', 'nLTOPX ',
     'nLTOPY ', 'nmSECS', 'oINV ', 'oPOLYTERM', 'oUNDER', 'nCOMPSIMPSON', 'nMUSICPOS', 'nMUSICLEN',
     'oBASE$', 'oIIF', 'oIIF$', 'nSEARCH', 'o MUL ', 'o DIV ', 'o ADD ', 'o SUB ', 'oGCD', 'oLCM', 'oDET',
     'oBIN ', 'nSPFRAME ', 'nSPCOLL ', 'nTEXTURE$ ', 'nINZONE', 'nMATCH', 'oDECIMAL', 'oUSING$', 'oJOIN$',
     'oLBOUND', 'oUBOUND', 'oARSIZE', 'oMANDEL', 'oHEX ', 'nSCREEN$', 'nDATE$ ', 'nTIME$ ', 'oREPLACE$',
     'oIVAL ', 'oREPMATCH$', 'nATTR ', 'nMIATTR', 'nLASTM', 'nLASTMI', 'nKEY$ ', 'nSPCLX ', 'nSPCLY ',
     'nDATADDR', 'nWINADDR', 'nMEMRD', 'nDMEMRD', 'nQMEMRD', 'nMEMRD$', 'nSTRADDR ', 'oCHOOSE', 'oCHOOSE$',
     'oTAU', 'nMILLISECONDS', 'oBINV', 'oBREV', 'oINTERP', 'oMIN$', 'oMAX$', 'nFMEMRD', 'nTXTw', 'nTXTh',
     'nNOISE', 'nOCTNOISE', 'oPAR ', 'oMAP', 'o EQV ', 'o IMP ', 'oSINH ', 'oCOSH ', 'oTANH ', 'oASNH ',
     'oACSH ', 'oATNH ', 'oMID', 'nPARAM$', 'nSTK', 'nSTK$', 'oREV$ ', 'nCLIP$');

  // Constants, like above, for identifying Functions in token form

  SP_FUNCTION_BASE          = 2000;

  SP_FN_RND                 = 2000;
  SP_FN_INKEYS              = 2001;
  SP_FN_PI                  = 2002;
  SP_FN_VALS                = 2003;
  SP_FN_CODE                = 2004;
  SP_FN_VAL                 = 2005;
  SP_FN_LEN                 = 2006;
  SP_FN_SIN                 = 2007;
  SP_FN_COS                 = 2008;
  SP_FN_TAN                 = 2009;
  SP_FN_ASN                 = 2010;
  SP_FN_ACS                 = 2011;
  SP_FN_ATN                 = 2012;
  SP_FN_LN                  = 2013;
  SP_FN_EXP                 = 2014;
  SP_FN_INT                 = 2015;
  SP_FN_SQR                 = 2016;
  SP_FN_SGN                 = 2017;
  SP_FN_ABS                 = 2018;
  SP_FN_IN                  = 2019;
  SP_FN_USR                 = 2020;
  SP_FN_STRS                = 2021;
  SP_FN_CHRS                = 2022;
  SP_FN_PEEK                = 2023;
  SP_FN_NOT                 = 2024;
  SP_FN_OR                  = 2025;
  SP_FN_AND                 = 2026;
  SP_FN_MOD                 = 2027;
  SP_FN_XOR                 = 2028;
  SP_FN_SHL                 = 2029;
  SP_FN_SHR                 = 2030;
  SP_FN_FRAC                = 2031;
  SP_FN_CEIL                = 2032;
  SP_FN_FLOOR               = 2033;
  SP_FN_MAX                 = 2034;
  SP_FN_MIN                 = 2035;
  SP_FN_ROUND               = 2036;
  SP_FN_ODD                 = 2037;
  SP_FN_EVEN                = 2038;
  SP_FN_POS                 = 2039;
  SP_FN_TRUNC               = 2040;
  SP_FN_LEFTS               = 2041;
  SP_FN_RIGHTS              = 2042;
  SP_FN_MIDS                = 2043;
  SP_FN_UPS                 = 2044;
  SP_FN_LOWS                = 2045;
  SP_FN_REPS                = 2046;
  SP_FN_RED                 = 2047;
  SP_FN_GREEN               = 2048;
  SP_FN_BLUE                = 2049;
  SP_FN_RGB                 = 2050;
  SP_FN_HEXS                = 2051;
  SP_FN_BINS                = 2052;
  SP_FN_RGBF                = 2053;
  SP_FN_RGBN                = 2054;
  SP_FN_KEY                 = 2055;
  SP_FN_HSV                 = 2056;
  SP_FN_RGBC                = 2057;
  SP_FN_HUE                 = 2058;
  SP_FN_SAT                 = 2059;
  SP_FN_VALUE               = 2060;
  SP_FN_WINW                = 2061;
  SP_FN_WINH                = 2062;
  SP_FN_SCRW                = 2063;
  SP_FN_SCRH                = 2064;
  SP_FN_CWIN                = 2065;
  SP_FN_RGBtoINT            = 2066;
  SP_FN_HSVtoINT            = 2067;
  SP_FN_RGBToHSV            = 2068;
  SP_FN_HSVToRGB            = 2069;
  SP_FN_TRIMS               = 2070;
  SP_FN_LTRIMS              = 2071;
  SP_FN_RTRIMS              = 2072;
  SP_FN_UDG                 = 2073;
  SP_FN_UDGS                = 2074;
  SP_FN_DPEEK               = 2075;
  SP_FN_QPEEK               = 2076;
  SP_FN_MOUSEX              = 2077;
  SP_FN_MOUSEY              = 2078;
  SP_FN_MOUSEBTN            = 2079;
  SP_FN_ERROR_NUM           = 2080;
  SP_FN_ERROR_LIN           = 2081;
  SP_FN_ERROR_STA           = 2082;
  SP_FN_DEGTORAD            = 2083;
  SP_FN_RADTODEG            = 2084;
  SP_FN_FONTBANK            = 2085;
  SP_FN_FONTWIDTH           = 2086;
  SP_FN_FONTHEIGHT          = 2087;
  SP_FN_FONTMODE            = 2088;
  SP_FN_FONTTRANSPARENT     = 2089;
  SP_FN_SLEN                = 2090;
  SP_FN_SPOS                = 2091;
  SP_FN_BSIZE               = 2092;
  SP_FN_GETDIR              = 2093;
  SP_FN_MOUSEDX             = 2094;
  SP_FN_MOUSEDY             = 2095;
  SP_FN_DCHRS               = 2096;
  SP_FN_QCHRS               = 2097;
  SP_FN_DCODE               = 2098;
  SP_FN_QCODE               = 2099;
  SP_FN_TOKENS              = 2100;
  SP_FN_HEADING             = 2101;
  SP_FN_DRPOSX              = 2102;
  SP_FN_DRPOSY              = 2103;
  SP_FN_CHPOS               = 2104;
  SP_FN_WINOFF              = 2105;
  SP_FN_CALL                = 2106;
  SP_FN_PEEKS               = 2107;
  SP_FN_LASTK               = 2108;
  SP_FN_SPFRADDR            = 2109;
  SP_FN_SPRITEX             = 2110;
  SP_FN_SPRITEY             = 2111;
  SP_FN_SPRITEW             = 2112;
  SP_FN_SPRITEH             = 2113;
  SP_FN_SPVISIBLE           = 2114;
  SP_FN_SPFCOUNT            = 2115;
  SP_FN_SPROT               = 2116;
  SP_FN_SPSCALE             = 2117;
  SP_FN_FRAMES              = 2118;
  SP_FN_TIME                = 2119;
  SP_FN_DAYS                = 2120;
  SP_FN_MONTHS              = 2121;
  SP_FN_YEAR                = 2122;
  SP_FN_HOUR                = 2123;
  SP_FN_MINUTES             = 2124;
  SP_FN_SECONDS             = 2125;
  SP_FN_DAY                 = 2126;
  SP_FN_MONTH               = 2127;
  SP_FN_MOUSEWHEEL          = 2128;
  SP_FN_GFXS                = 2129;
  SP_FN_GRGB                = 2130;
  SP_FN_GHSV                = 2131;
  SP_FN_WINX                = 2132;
  SP_FN_WINY                = 2133;
  SP_FN_GFXW                = 2134;
  SP_FN_GFXH                = 2135;
  SP_FN_GFXT                = 2136;
  SP_FN_GPOINT              = 2137;
  SP_FN_FPEEK               = 2138;
  SP_FN_ITEM                = 2139;
  SP_FN_FCODE               = 2140;
  SP_FN_FCHRS               = 2141;
  SP_FN_POWER               = 2142;
  SP_FN_DIR                 = 2143;
  SP_FN_POINT               = 2144;
  SP_FN_FN                  = 2145;
  SP_FN_GETTILE             = 2146;
  SP_FN_POWERTWO            = 2147;
  SP_FN_LOGTWO              = 2148;
  SP_FN_WORDSWAP            = 2149;
  SP_FN_BYTESWAP            = 2150;
  SP_FN_NYBBLESWAP          = 2151;
  SP_FN_POLAR               = 2152;
  SP_FN_CLAMP               = 2153;
  SP_FN_INRANGE             = 2154;
  SP_FN_INSERTS             = 2155;
  SP_FN_ITEMS               = 2156;
  SP_FN_BIT                 = 2157;
  SP_FN_HIWORD              = 2158;
  SP_FN_LOWORD              = 2159;
  SP_FN_HIBYTE              = 2160;
  SP_FN_LOBYTE              = 2161;
  SP_FN_POLARDIST           = 2162;
  SP_FN_LPADS               = 2163;
  SP_FN_RPADS               = 2164;
  SP_FN_PROCID              = 2165;
  SP_FN_PROCIDS             = 2166;
  SP_FN_BTSET               = 2167;
  SP_FN_BTCLR               = 2168;
  SP_FN_ERRORS              = 2169;
  SP_FN_MENUBOX             = 2170;
  SP_FN_POPLINE             = 2171;
  SP_FN_POPST               = 2172;
  SP_FN_VOL                 = 2173;
  SP_FN_GETOPT              = 2174;
  SP_FN_GETOPTS             = 2175;
  SP_FN_NUBMODE             = 2176;
  SP_FN_NUBX                = 2177;
  SP_FN_NUBY                = 2178;
  SP_FN_FEXISTS             = 2179;
  SP_FN_FPATH               = 2180;
  SP_FN_FNAME               = 2181;
  SP_FN_DEXISTS             = 2182;
  SP_FN_PYTH                = 2183;
  SP_FN_LOGW                = 2184;
  SP_FN_LOGH                = 2185;
  SP_FN_ORGX                = 2186;
  SP_FN_ORGY                = 2187;
  SP_FN_PTOLX               = 2188;
  SP_FN_PTOLY               = 2189;
  SP_FN_LTOPX               = 2190;
  SP_FN_LTOPY               = 2191;
  SP_FN_MSECS               = 2192;
  SP_FN_INV                 = 2193;
  SP_FN_POLYTERM            = 2194;
  SP_FN_UNDER               = 2195;
  SP_FN_COMPSIMPSON         = 2196;
  SP_FN_MUSICPOS            = 2197;
  SP_FN_MUSICLEN            = 2198;
  SP_FN_BASES               = 2199;
  SP_FN_IIF                 = 2200;
  SP_FN_IIFS                = 2201;
  SP_FN_SEARCH              = 2202;
  SP_FN_MUL                 = 2203;
  SP_FN_DIV                 = 2204;
  SP_FN_ADD                 = 2205;
  SP_FN_SUB                 = 2206;
  SP_FN_GCD                 = 2207;
  SP_FN_LCM                 = 2208;
  SP_FN_DET                 = 2209;
  SP_FN_BIN                 = 2210;
  SP_FN_SPFRAME             = 2211;
  SP_FN_SPCOLL              = 2212;
  SP_FN_TEXTURES            = 2213;
  SP_FN_INZONE              = 2214;
  SP_FN_MATCH               = 2215;
  SP_FN_DECIMAL             = 2216;
  SP_FN_USINGS              = 2217;
  SP_FN_JOINS               = 2218;
  SP_FN_LBOUND              = 2219;
  SP_FN_UBOUND              = 2220;
  SP_FN_ARSIZE              = 2221;
  SP_FN_MANDEL              = 2222;
  SP_FN_HEX                 = 2223;
  SP_FN_SCREENS             = 2224;
  SP_FN_DATES               = 2225;
  SP_FN_TIMES               = 2226;
  SP_FN_REPLACES            = 2227;
  SP_FN_IVAL                = 2228;
  SP_FN_REPLACEMATCHS       = 2229;
  SP_FN_ATTR                = 2230;
  SP_FN_MIATTR              = 2231;
  SP_FN_LASTM               = 2232;
  SP_FN_LASTMI              = 2233;
  SP_FN_KEYS                = 2234;
  SP_FN_SPCLX               = 2235;
  SP_FN_SPCLY               = 2236;
  SP_FN_DATADDR             = 2237;
  SP_FN_WINADDR             = 2238;
  SP_FN_MEMRD               = 2239;
  SP_FN_DMEMRD              = 2240;
  SP_FN_QMEMRD              = 2241;
  SP_FN_MEMRDS              = 2242;
  SP_FN_STRADDR             = 2243;
  SP_FN_CHOOSE              = 2244;
  SP_FN_CHOOSES             = 2245;
  SP_FN_TAU                 = 2246;
  SP_FN_MILLISECONDS        = 2247;
  SP_FN_BINV                = 2248;
  SP_FN_BREV                = 2249;
  SP_FN_INTERP              = 2250;
  SP_FN_MINS                = 2251;
  SP_FN_MAXS                = 2252;
  SP_FN_FMEMRD              = 2253;
  SP_FN_TXTW                = 2254;
  SP_FN_TXTH                = 2255;
  SP_FN_NOISE               = 2256;
  SP_FN_NOISEOCT            = 2257;
  SP_FN_PAR                 = 2258;
  SP_FN_MAP                 = 2259;
  SP_FN_EQV                 = 2260;
  SP_FN_IMP                 = 2261;
  SP_FN_SINH                = 2262;
  SP_FN_COSH                = 2263;
  SP_FN_TANH                = 2264;
  SP_FN_ASNH                = 2265;
  SP_FN_ACSH                = 2266;
  SP_FN_ATNH                = 2267;
  SP_FN_MID                 = 2268;
  SP_FN_PARAMS              = 2269;
  SP_FN_STK                 = 2270;
  SP_FN_STKS                = 2271;
  SP_FN_REVS                = 2272;
  SP_FN_CLIPS               = 2273;

  // Meta-functions

  SP_META_BASE = 3000;
  SP_Function_Names: Array[0..6] of aString =
   ('nSEARCH_NEXT', 'nSP_MENUBOX_EX', 'oSP_iRGBtoHSV', 'oSP_iHSVtoRGB', 'nSP_iRGBf', 'nSP_iRGBn', 'nSP_POSN');

  SP_FN_SEARCH_NEXT         = 3000;
  SP_FN_MENUBOX_EX          = 3001;
  SP_FN_iRGBtoHSV           = 3002;
  SP_FN_iHSVtoRGB           = 3003;
  SP_FN_iRGBf               = 3004;
  SP_FN_iRGBn               = 3005;
  SP_FN_POSN                = 3006;

  // List of token types.

  SP_KEYWORD                = 0;
  SP_VALUE10                = 1;
  SP_STRING                 = 2;
  SP_NUMVAR                 = 3;
  SP_STRVAR                 = 4;
  SP_TEXT                   = 5;
  SP_SYMBOL                 = 6;
  SP_FUNCTION               = 7;
  SP_UNKNOWN                = 8;
  SP_OPERATOR               = 9;
  SP_COMMA                  = 10;
  SP_ARRAYPARAM             = 11;
  SP_FUNCTION_EX            = 12;
  SP_LINE_NUM               = 13;
  SP_STATEMENTS             = 14;
  SP_NUMVAR_EVAL            = 15;
  SP_STRVAR_EVAL            = 16;
  SP_ARRAY                  = 17;
  SP_SLICER                 = 18;
  SP_ARRAY_ASSIGN           = 19;
  SP_SLICE_ASSIGN           = 20;
  SP_NULL                   = 21;
  SP_POINTER                = 22;
  SP_SKIP_STATEMENT         = 23;
  SP_SKIP_LINE              = 24;
  SP_DATA_ITEM              = 25;
  SP_LABEL                  = 26;
  SP_LINE_LEN               = 27;
  SP_DISPLACEMENT           = 28;
  SP_SLICE_VAR              = 29;
  SP_VALUE                  = 30;
  SP_STRINGCHAR             = 31;
  SP_PARAMETER              = 32;
  SP_NUMVAR_LET             = 33;
  SP_STRVAR_LET             = 34;
  SP_STRUCT_MEMBER_N        = 35;
  SP_STRUCT_MEMBER_ASS      = 36;
  SP_STRUCT_MEMBER_S        = 37;
  SP_STRVARPTR              = 38;
  SP_NUMVAR_LET_VALID       = 39;
  SP_STRVAR_LET_VALID       = 40;
  SP_SKIP_DATA              = 41;
  SP_RANGE_LESS             = 42;
  SP_RANGE_GREATER          = 43;
  SP_RANGE                  = 44;
  SP_FUNCTION_MARKER        = 45;
  SP_COMPOUND_NNO           = 46;
  SP_COMPOUND_NVO           = 47;
  SP_COMPOUND_VNO           = 48;
  SP_SPECIAL_SYMBOL         = 49;
  SP_INTEGER                = 50;
  SP_EACHSINGLE             = 51;
  SP_EACHRANGE              = 52;
  SP_EACHSTEP               = 53;
  SP_NUMCONST               = 54;
  SP_STRCONST               = 55;
  SP_INTVAR                 = 56;
  SP_RANGE_ARRAYSTR         = 57;
  SP_RANGE_ARRAYNUM         = 58;
  SP_SLICE_ARRAY            = 59;
  SP_INCVAR                 = 60;
  SP_DECVAR                 = 61;
  SP_MULVAR                 = 62;
  SP_DIVVAR                 = 63;
  SP_POWVAR                 = 64;
  SP_MODVAR                 = 65;
  SP_ANDVAR                 = 66;
  SP_XORVAR                 = 67;
  SP_ORVAR                  = 68;
  SP_JZ                     = 69;
  SP_JNZ                    = 70;
  SP_COMMENT                = 71;
  SP_NUM_ARRAY_PTR          = 72;
  SP_LITERAL_SYMBOL         = 73;
  SP_NUMVARSQ               = 74;
  SP_BLOCK_OPT              = 75;
  SP_RESTORECOLOURS         = 76;
  SP_NOTVAR                 = 77;
  SP_IJMP                   = 78;
  SP_HYBRID_LET             = 79;
  SP_JUMP                   = 100;
  SP_RUN                    = 101;
  SP_NEW                    = -2;
  SP_EXIT                   = -1;

  SP_TERMINAL               = 255;
  SP_TERMINAL_CHAR          = #255;
  SP_TERMINAL_SEQUENCE      = #255+#255+#255+#255;

  SP_FUNCTION_ID            = #255;
  SP_CHAR_GTE               = #254;
  SP_CHAR_LTE               = #253;
  SP_CHAR_DNE               = #252;
  SP_CHAR_AND               = #251;
  SP_CHAR_OR                = #250;
  SP_CHAR_UNARYM            = #249;
  SP_CHAR_UNARYP            = #248;
  SP_CHAR_MOD               = #247;
  SP_CHAR_XOR               = #246;
  SP_CHAR_SHL               = #245;
  SP_CHAR_SHR               = #244;
  SP_CHAR_STR_PLUS          = #243;
  SP_CHAR_NUM_PLUS          = #242;
  SP_CHAR_STR_EQU           = #241;
  SP_CHAR_NUM_EQU           = #240;
  SP_CHAR_NUM_LES           = #239;
  SP_CHAR_STR_LES           = #238;
  SP_CHAR_NUM_LTE           = #237;
  SP_CHAR_STR_LTE           = #236;
  SP_CHAR_NUM_DNE           = #235;
  SP_CHAR_STR_DNE           = #234;
  SP_CHAR_NUM_GTE           = #233;
  SP_CHAR_STR_GTE           = #232;
  SP_CHAR_NUM_GTR           = #231;
  SP_CHAR_STR_GTR           = #230;
  SP_CHAR_NUM_AND           = #229;
  SP_CHAR_STR_AND           = #228;
  SP_CHAR_STR_MUL1          = #227;
  SP_CHAR_STR_MUL2          = #226;
  SP_CHAR_DIV               = #225;
  SP_CHAR_MUL               = #224;
  SP_CHAR_ADD               = #223;
  SP_CHAR_SUB               = #222;
  SP_CHAR_INT_PLUS          = #221;
  SP_CHAR_INCVAR            = #220;
  SP_CHAR_DECVAR            = #219;
  SP_CHAR_MULVAR            = #218;
  SP_CHAR_DIVVAR            = #217;
  SP_CHAR_POWVAR            = #216;
  SP_CHAR_MODVAR            = #215;
  SP_CHAR_ANDVAR            = #214;
  SP_CHAR_XORVAR            = #213;
  SP_CHAR_ORVAR             = #212;
  SP_CHAR_NOT               = #211;
  SP_CHAR_BITWISE_NOT       = #210;
  SP_CHAR_STRING_NOT        = #209;
  SP_CHAR_EQV               = #208;
  SP_CHAR_IMP               = #207;
  SP_CHAR_SEMICOLON         = #206;
  SP_CHAR_NOTVAR            = #205;

  SP_CHAR_PLUS              = '+';
  SP_CHAR_MINUS             = '-';
  SP_CHAR_MULTIPLY          = '*';
  SP_CHAR_DIVIDE            = '/';
  SP_CHAR_POWER             = '^';
  SP_CHAR_COLON             = ':';
  SP_CHAR_EQUALS            = '=';
  SP_CHAR_GREATER           = '>';
  SP_CHAR_LESS              = '<';
  SP_CHAR_BIT_OR            = '|';
  SP_CHAR_BIT_AND           = '&';
  SP_CHAR_EXCLAIM           = '!';
  SP_CHAR_TILDE             = '~';

  SP_PR_STOP                = 2;
  SP_PR_RUN                 = 1;

  SP_TRUE                   = 1;
  SP_FALSE                  = 0;

  HybridFns: Array[0..0] of LongWord = (SP_FN_CLIPS);

implementation

Uses SP_Main, SP_Editor, SP_FileIO, SP_SysVars, {$IFDEF FPC}LclIntf{$ELSE}Windows{$ENDIF};

Function SP_IsHybridFn(const Idx: LongWord): Boolean;
Var
  i: Integer;
Begin
  i := 0;
  Result := False;
  While i <= High(HybridFns) do
    if HybridFns[i] = Idx Then Begin
      Result := True;
      Exit;
    End Else
      Inc(i);
End;

Function SP_TokeniseLine(Line: aString; IsExpression, AddLineNum: Boolean): aString;
Var
  TempExtend: aFloat;
  Keyword, SpaceMod: Integer;
  StoreVal, StoreLen, TempVal, LineLen, Idx, tIdx, lIdx, cnt, l: Integer;
  StoreText, tStore, tempStr, tStr: aString;
  FoundBase: Boolean;
  rPtr, rStart, rEnd: {$IFDEF FPC}Integer{$ELSE}pByte{$ENDIF};
Label
  Finish;
Const
  Compounds: Array[0..15] of TCompoundWord =
    ((Name: 'DEFPROC'; KeyWordID: SP_KW_DEF_PROC),
     (Name: 'DEFFN'; KeyWordID: SP_KW_DEF_FN),
     (Name: 'DEFSTRUCT'; KeyWordID: SP_KW_DEF_STRUCT),
     (Name: 'DEF PROC'; KeyWordID: SP_KW_DEF_PROC),
     (Name: 'DEF FN'; KeyWordID: SP_KW_DEF_FN),
     (Name: 'DEF STRUCT'; KeyWordID: SP_KW_DEF_STRUCT),
     (Name: 'ENDPROC'; KeyWordID: SP_KW_ENDPROC),
     (Name: 'ENDIF'; KeyWordID: SP_KW_ENDIF),
     (Name: 'ENDSTRUCT'; KeyWordID: SP_KW_ENDSTRUCT),
     (Name: 'END PROC'; KeyWordID: SP_KW_ENDPROC),
     (Name: 'END IF'; KeyWordID: SP_KW_ENDIF),
     (Name: 'END STRUCT'; KeyWordID: SP_KW_ENDSTRUCT),
     (Name: 'EXIT PROC'; KeyWordID: SP_KW_EXIT_PROC),
     (Name: 'EXITPROC'; KeyWordID: SP_KW_EXIT_PROC),
     (Name: 'END CASE'; KeyWordID: SP_KW_END_CASE),
     (Name: 'ENDCASE'; KeyWordID: SP_KW_END_CASE));

  procedure AddToResult(const str: aString);
  begin
    l := Length(Str);
    {$IFNDEF FPC}
    MoveMemory(rPtr, pByte(pNativeUInt(@str)^), l);
    {$ELSE}
    Move(str[1], Result[rPtr], l);
    {$ENDIF}
    inc(rPtr, l);
  end;

Begin

  // Iterate through the line, picking up keywords and translating them into
  // their LONGWORD equivalents. Values should be converted into aFloat form
  // and stored. Strings go in as-is, with a STRINGID byte followed by a LONGWORD
  // Length byte.

  {$IFDEF FPC}
  SetLength(Result, SizeOf(TToken) * Max(Length(Line), 50));
  rptr := 1;
  {$ELSE}
  SetLength(Result, SizeOf(TToken) * Max(Length(Line), 50));
  rptr := pByte(pNativeUInt(@Result)^);
  {$ENDIF}
  rStart := rPtr;
  Idx := 1;

  While Copy(Line, 1, 1) = ' ' Do
    Line := Copy(Line, 2, Length(Line));

  While (Line <> '') And (Line[Length(Line)] in [#0..#32, ':']) Do
    Line := Copy(Line, 1, Length(Line) -1);

  LineLen := Length(Line);

  If Line <> '' Then Begin

    // Pick up a possible line number - beware though, it could be a calculation.
    // Number on its own - delete line number. Number followed by keyword - command.
    // Number followed by function or operator - calculation.

    SP_SkipSpaces(Line, Idx);

    If AddLineNum Then
      If Not IsExpression Then Begin
        StoreVal := Idx;
        If SP_GetNumber(Line, Idx, TempExtend) Then Begin
          TempExtend := Min($FFFFFFFF, TempExtend);
          If TempExtend = Round(TempExtend) Then Begin
            If (Idx > LineLen) Or (Line[Idx] <> '\') Then // A number followed by a backslash is a base, not a line number.
              AddToResult(aChar(SP_LINE_NUM) + LongWordToString(Round(TempExtend)))
            Else
              Idx := StoreVal;
          End Else
            Idx := StoreVal;
        End Else
          Idx := StoreVal;
      End;

    While Idx <= LineLen Do Begin

      SP_SkipSpaces(Line, Idx);
      If Idx > LineLen Then Goto Finish;
      SpaceMod := 0;

      // A number at this position? Might need to look ahead for a base operator - "\"

      tIdx := Idx;
      StoreText := '';
      FoundBase := False;
      While (tIdx <= LineLen) And (Line[tIdx] in [' ', 'A'..'Z', 'a'..'z', '0'..'9', '\']) Do Begin
        If Line[tIdx] = '\' Then Break;
        StoreText := StoreText + Line[tIdx];
        Inc(tIdx);
      End;

      If (tIdx <= LineLen) and (Line[tIdx] = '\') Then Begin
        Inc(tIdx);
        StoreVal := 0;
        While (tIdx <= LineLen) And (Line[tIdx] in ['0'..'9']) Do Begin
          StoreVal := (Ord(Line[tIdx]) - 48) + (StoreVal * 10);
          Inc(tIdx);
        End;
        If (StoreVal < 37) And (StoreVal > 1) Then Begin
          tStr := '\'+IntToString(StoreVal);
          StoreLen := Length(StoreText) + Length(tStr);
          FoundBase := DecodeBase(StoreText, StoreVal);
          If FoundBase Then Begin
            Idx := tIdx;
            AddToResult(aChar(SP_VALUE) + aFloatToString(StoreVal) + aChar(SP_TEXT) + LongWordToString(StoreLen) + StoreText + tStr);
          End;
        End;
      End;

      If Not FoundBase Then
        If Line[Idx] in ['.', '0'..'9', '%', '$'] Then Begin
          StoreVal := Idx;
          If SP_GetNumber(Line, Idx, TempExtend) Then Begin
            StoreLen := Idx - StoreVal;
            StoreText := Copy(Line, StoreVal, StoreLen);
            AddToResult(aChar(SP_VALUE) + aFloatToString(TempExtend) + aChar(SP_TEXT) + LongWordToString(StoreLen) + StoreText);
          End Else Begin
            // Not a number, even though we thought it might be - so is it a structure member?
            If (StoreVal < Length(Line)) and (line[StoreVal] = '.') and (Line[StoreVal +1] in ['A'..'Z', 'a'..'z']) Then Begin
              Idx := StoreVal +1;
              If Idx <= LineLen Then Begin
                If Line[Idx] in ['A'..'Z', 'a'..'z'] Then Begin
                  StoreText := '';
                  While (Idx <= LineLen) And (Line[Idx] in ['0'..'9', 'A'..'Z', 'a'..'z', '_', '$']) Do Begin
                    StoreText := StoreText + Line[Idx];
                    Inc(Idx);
                    If StoreText[Length(StoreText)] = '$' Then Break;
                  End;
                  If Not SP_IsReserved(Upper(StoreText)) Then Begin
                    If Line[Idx -1] = '$' Then
                      AddToResult(aChar(SP_STRUCT_MEMBER_S) + LongWordToString(Length(StoreText)) + StoreText)
                    Else
                      AddToResult(aChar(SP_STRUCT_MEMBER_N) + LongWordToString(Length(StoreText)) + StoreText);
                  End Else Begin
                    AddToResult(aChar(SP_SYMBOL) + Line[StoreVal]);
                    Idx := StoreVal +1;
                  End;
                End;
              End;
            End Else
              // Nope, wasn't a structure member, so just leave it here and let the parser deal with it.
              AddToResult(aChar(SP_SYMBOL) + Line[StoreVal]);
          End;
        End Else

          // Could it be a String?

          If Line[Idx] in ['"', '#'] Then Begin

            If Line[Idx] = '"' Then Begin

              StoreText := '';

              While True Do Begin

                Inc(Idx);
                If (Idx <= LineLen) Then Begin
                  If Line[Idx] = '"' Then Begin
                    If (Idx < LineLen) And (Line[Idx+1] = '"') Then Begin
                      StoreText := StoreText + '"';
                      Inc(Idx);
                    End Else Begin
                      Inc(Idx);
                      Break;
                    End;
                  End Else
                    StoreText := StoreText + Line[Idx];
                End Else
                  Break;

              End;

              StoreLen := Length(StoreText);
              AddToResult(aChar(SP_STRING) + LongWordToString(StoreLen) + StoreText);

            End Else Begin
              Inc(Idx);
              If (Idx <= LineLen) And (Line[Idx] in ['0'..'9', '$', '%']) Then Begin
                StoreVal := Idx;
                If SP_GetNumber(Line, Idx, TempExtend) Then Begin
                  StoreLen := Idx - StoreVal;
                  StoreText := Copy(Line, StoreVal, StoreLen);
                  AddToResult(aChar(SP_STRINGCHAR) + aFloatToString(TempExtend) + aChar(SP_TEXT) + LongWordToString(StoreLen) + StoreText);
                End Else Begin
                  // Not a number, even though we thought it might be - so store it as a random char.
                  AddToResult(aChar(SP_SYMBOL) + Line[StoreVal]);
                  Inc(Idx);
                End;
              End;
            End;

          End Else

            // A numeric variable? Or a String variable? Or a Keyword? Or a Const?

            If Line[Idx] in ['A'..'Z', 'a'..'z'] Then Begin
              StoreText := '';
              TempVal := Idx;
              While (Idx <= LineLen) And (Line[Idx] in ['0'..'9', 'A'..'Z', 'a'..'z', '_', ' ']) Do Begin
                StoreText := StoreText + Line[Idx];
                Inc(Idx);
              End;
              If Idx <= LineLen Then
                If Line[Idx] = '$' Then Begin
                  StoreText := StoreText + '$';
                  Inc(Idx);
                End;
              tIdx := Idx;
              tStore := StoreText;
              If Copy(StoreText, Length(StoreText), 1) = '_' Then
                While (Idx <= LineLen) And (Line[Idx] in ['0'..'9', '_']) Do Begin
                    StoreText := StoreText + Line[Idx];
                    Inc(Idx);
                  End;

              KeyWord := -1;
              Idx := tIdx;
              StoreText := tStore;
              // Test for compound-word commands - DEF PROC/END PROC/GO TO etc. They will have been picked up as
              // potential variable names ("DEF PROC myproc" would be valid for a variable if DEF PROC didn't exist!)
              If Copy(Upper(StoreText), 1, 2) = 'GO' Then Begin
                // "GO" is a special case, but only if it is followed by "TO" or "SUB".
                If (Copy(Upper(StoreText), 3, 2) = 'TO') or (Copy(Upper(StoreText), 3, 3) = 'SUB') Then Begin
                  Dec(Idx, Length(StoreText) -2);
                  StoreText := Copy(StoreText, 1, 2);
                End;
              End;
              TempStr := Upper(StoreText);
              For lIdx := 0 To High(Compounds) Do Begin
                If Copy(TempStr, 1, Length(Compounds[lIdx].Name)) = Compounds[lIdx].Name Then Begin
                  Dec(Idx, Length(StoreText) - Length(Compounds[lIdx].Name));
                  StoreText := Compounds[lIdx].Name;
                  KeyWord := Compounds[lIdx].KeyWordID;
                  SpaceMod := 0;
                  Break;
                End;
              End;

              // A small spelling check - you can be merkin if you want.

              If Upper(StoreText) = 'RANDOMISE' Then StoreText := 'RANDOMIZE';

              // A bit of a hack - if there's a space in this text, then test each word for a match with a reserved word.
              // Cut off at the first reserved word - this allows the CIRCLE command to work with a FILL command.
              If (Pos(' ', StoreText) <> 0) And (KeyWord = -1) Then Begin
                If StoreText[Length(StoreText)] <> ' ' Then
                  StoreText := StoreText + ' ';
                tStore := Upper(StoreText);
                TempStr := '';
                Dec(Idx, Length(StoreText));
                While Pos(' ', tStore) <> 0 Do Begin
                  tStr := Copy(tStore, 1, Pos(' ', tStore) -1);
                  If (SP_IsFunction(tStr) > -1) or (SP_IsKeyWord(tStr) > -1) Then Begin
                    If TempStr = '' Then Begin
                      TempStr := tStr;
                      Inc(Idx, Length(tStr));
                    End;
                    Break;
                  End Else Begin
                    tStore := Copy(tStore, Pos(' ', tStore), Length(tStore));
                    TempStr := TempStr + tStr;
                    While (tStore <> '') And (tStore[1] = ' ') Do Begin
                      TempStr := TempStr + ' ';
                      tStore := Copy(tStore, 2, Length(tStore));
                      Inc(Idx);
                    End;
                    Inc(Idx, Length(tStr));
                  End;
                End;
                StoreText := Copy(StoreText, 1, Length(TempStr));
                While StoreText[Length(StoreText)] = ' ' Do
                  StoreText := Copy(StoreText, 1, Length(StoreText) -1);
              End;

              lIdx := -1;
              If KeyWord = -1 Then lIdx := SP_IsConstant(Upper(StoreText));
              If lIdx > -1 Then Begin
                StoreText := SP_Constants[lIdx].Name;
                TempExtend := SP_Constants[lIdx].Value;
                StoreLen := Length(StoreText);
                AddToResult(aChar(SP_VALUE) + aFloatToString(TempExtend) + aChar(SP_TEXT) + LongWordToString(StoreLen) + StoreText);
              End Else Begin
                If KeyWord = -1 Then
                  KeyWord := SP_IsKeyWord(Upper(StoreText))
                Else
                  Dec(KeyWord , SP_KEYWORD_BASE);
                If KeyWord > -1 Then Begin
                  AddToResult(aChar(SP_KEYWORD) + LongWordToString(KeyWord + SP_KEYWORD_BASE));
                  Idx := TempVal + Length(SP_KEYWORDS[KeyWord]) + SpaceMod;
                  If KeyWord + SP_KEYWORD_BASE = SP_KW_REM Then Begin
                    StoreText := Copy(Line, Idx, Length(Line));
                    AddToResult(aChar(SP_TEXT) + LongWordToString(Length(StoreText)) + StoreText);
                    Goto Finish;
                  End;
                End Else Begin
                  KeyWord := SP_IsFunction(Upper(StoreText));
                  If KeyWord > -1 Then Begin
                    If KeyWord + SP_FUNCTION_BASE = SP_FN_HEX Then Begin
                      AddToResult(aChar(SP_FUNCTION) + LongWordToString(KeyWord + SP_FUNCTION_BASE));
                      TempVal := Idx -2;
                      Inc(Idx);
                      SP_SkipSpaces(Line, Idx);
                      StoreText := '';
                      StoreLen := 0;
                      While (Idx < Length(Line)) And (Line[Idx] in ['A'..'F', 'a'..'f', '0'..'9']) Do Begin
                        StoreText := StoreText + Line[Idx];
                        Inc(StoreLen);
                        Inc(Idx);
                      End;
                      If StoreLen <> 0 Then Begin
                        TempVal := Idx + 2;
                        AddToResult(aChar(SP_NUMVAR) + LongWordToString(0) + LongWordToString(StoreLen) + StoreText);
                      End;
                      Dec(Idx, 3);
                    End Else
                      If KeyWord + SP_FUNCTION_BASE = SP_FN_AND Then
                        AddToResult(aChar(SP_SYMBOL) + SP_CHAR_AND)
                      Else
                        If KeyWord + SP_FUNCTION_BASE = SP_FN_OR Then
                          AddToResult(aChar(SP_SYMBOL) + SP_CHAR_OR)
                        Else
                          If KeyWord + SP_FUNCTION_BASE = SP_FN_MOD Then
                            AddToResult(aChar(SP_SYMBOL) + SP_CHAR_MOD)
                          Else
                            If KeyWord + SP_FUNCTION_BASE = SP_FN_XOR Then
                              AddToResult(aChar(SP_SYMBOL) + SP_CHAR_XOR)
                            Else
                              If KeyWord + SP_FUNCTION_BASE = SP_FN_SHL Then
                                AddToResult(aChar(SP_SYMBOL) + SP_CHAR_SHL)
                              Else
                                If KeyWord + SP_FUNCTION_BASE = SP_FN_SHR Then
                                  AddToResult(aChar(SP_SYMBOL) + SP_CHAR_SHR)
                                Else
                                  If KeyWord + SP_FUNCTION_BASE = SP_FN_MUL Then
                                    AddToResult(aChar(SP_SYMBOL) + SP_CHAR_MUL)
                                  Else
                                    If KeyWord + SP_FUNCTION_BASE = SP_FN_DIV Then
                                      AddToResult(aChar(SP_SYMBOL) + SP_CHAR_DIV)
                                    Else
                                      If KeyWord + SP_FUNCTION_BASE = SP_FN_ADD Then
                                        AddToResult(aChar(SP_SYMBOL) + SP_CHAR_ADD)
                                      Else
                                        If KeyWord + SP_FUNCTION_BASE = SP_FN_SUB Then
                                          AddToResult(aChar(SP_SYMBOL) + SP_CHAR_SUB)
                                        Else
                                          If KeyWord + SP_FUNCTION_BASE = SP_FN_NOT Then
                                            AddToResult(aChar(SP_SYMBOL) + SP_CHAR_NOT)
                                          Else
                                            If KeyWord + SP_FUNCTION_BASE = SP_FN_EQV Then
                                              AddToResult(aChar(SP_SYMBOL) + SP_CHAR_EQV)
                                            Else
                                              If KeyWord + SP_FUNCTION_BASE = SP_FN_IMP Then
                                                AddToResult(aChar(SP_SYMBOL) + SP_CHAR_IMP)
                                              Else
                                                AddToResult(aChar(SP_FUNCTION) + LongWordToString(KeyWord + SP_FUNCTION_BASE));
                    Idx := TempVal + Length(SP_FUNCTIONS[KeyWord]);
                  End Else Begin
                    If StoreText[Length(StoreText)] = '$' Then
                      StoreText := Copy(StoreText, 1, Length(StoreText) -1);
                    StoreLen := Length(StoreText);
                    If (Idx <= LineLen +1) And (Line[Idx-1] = '$') Then
                      AddToResult(aChar(SP_STRVAR) + LongWordToString(0) + LongWordToString(StoreLen) + StoreText)
                    Else
                      AddToResult(aChar(SP_NUMVAR) + LongWordToString(0) + LongWordToString(StoreLen) + StoreText);
                  End;
                End;
              End;
            End Else Begin
              // must be a random character - a comma or period, perhaps.
              If rPtr <> rStart Then
                If Line[Idx] = ':' Then Begin
                  AddToResult(aChar(SP_SYMBOL) + ':');
                End Else
                  If Line[Idx] = '@' Then Begin
                    Inc(Idx);
                    StoreText := '@';
                    While (Idx <= LineLen) And (Line[Idx] in ['0'..'9', 'A'..'Z', 'a'..'z', '_']) Do Begin
                      StoreText := StoreText + Line[Idx];
                      Inc(Idx);
                    End;
                    AddToResult(aChar(SP_LABEL) + LongWordToString(Length(StoreText)) + StoreText);
                    Dec(Idx);
                  End Else
                    {$IFDEF FPC}
                    If (Ord(Result[rPtr -2]) = SP_SYMBOL) And (line[Idx] = '=') Then Begin
                      rEnd := rPtr -1;
                      Case Result[rEnd] of
                        '>': Result[rEnd] := SP_CHAR_GTE;
                        '<': Result[rEnd] := SP_CHAR_LTE;
                        '+': Result[rEnd] := SP_CHAR_INCVAR;
                        '-': Result[rEnd] := SP_CHAR_DECVAR;
                        '*': Result[rEnd] := SP_CHAR_MULVAR;
                        '/': Result[rEnd] := SP_CHAR_DIVVAR;
                        '^': Result[rEnd] := SP_CHAR_POWVAR;
                        '%': Result[rEnd] := SP_CHAR_MODVAR;
                        '&': Result[rEnd] := SP_CHAR_ANDVAR;
                        '|': Result[rEnd] := SP_CHAR_ORVAR;
                        '~': Result[rEnd] := SP_CHAR_XORVAR;
                        '!': Result[rEnd] := SP_CHAR_NOTVAR;
                    {$ELSE}
                    If (pByte(NativeUInt(rPtr) -2)^ = SP_SYMBOL) And (Line[Idx] = '=') Then Begin
                      rEnd := pByte(NativeUInt(rPtr) -1);
                      Case aChar(rEnd^) of
                        '>': rEnd^ := Ord(SP_CHAR_GTE);
                        '<': rEnd^ := Ord(SP_CHAR_LTE);
                        '+': rEnd^ := Ord(SP_CHAR_INCVAR);
                        '-': rEnd^ := Ord(SP_CHAR_DECVAR);
                        '*': rEnd^ := Ord(SP_CHAR_MULVAR);
                        '/': rEnd^ := Ord(SP_CHAR_DIVVAR);
                        '^': rEnd^ := Ord(SP_CHAR_POWVAR);
                        '%': rEnd^ := Ord(SP_CHAR_MODVAR);
                        '&': rEnd^ := Ord(SP_CHAR_ANDVAR);
                        '|': rEnd^ := Ord(SP_CHAR_ORVAR);
                        '~': rEnd^ := Ord(SP_CHAR_XORVAR);
                        '!': rEnd^ := Ord(SP_CHAR_NOTVAR);
                    {$ENDIF}
                      Else
                        If Line[Idx] > #127 Then
                          AddToResult(aChar(SP_LITERAL_SYMBOL) + Line[Idx])
                        Else
                          AddToResult(aChar(SP_SYMBOL) + Line[Idx]);
                      End;
                    End Else Begin
                      If Line[Idx] = '{' Then Begin
                        tStr := ''; cnt := 0; Inc(Idx);
                        While Idx < Length(Line) Do Begin
                          If Line[Idx] = '{' Then Inc(Cnt);
                          If Line[Idx] = '}' Then Begin
                            Dec(Cnt);
                            If Cnt < 0 Then Break;
                          End;
                          tStr := tStr + Line[Idx];
                          Inc(Idx);
                        End;
                      End Else
                        {$IFDEF FPC}
                        If Ord(Result[rPtr -2]) = SP_SYMBOL Then Begin
                          rEnd := rPtr -1;
                          If (Line[Idx] = '>') And (Result[rEnd] = '<') Then
                            Result[rEnd] := SP_CHAR_DNE
                        {$ELSE}
                        If pByte(NativeUInt(rPtr) -2)^ = SP_SYMBOL Then Begin
                          rEnd := pByte(NativeUInt(rPtr) -1);
                          If (Line[Idx] = '>') And (rEnd^ = Ord('<')) Then
                            rEnd^ := Ord(SP_CHAR_DNE)
                        {$ENDIF}
                          Else Begin
                            If Line[Idx] > #127 Then
                              AddToResult(aChar(SP_LITERAL_SYMBOL) + Line[Idx])
                            Else
                              AddToResult(aChar(SP_SYMBOL) + Line[Idx]);
                          End;
                        End Else
                          If Line[Idx] > #127 Then
                            AddToResult(aChar(SP_LITERAL_SYMBOL) + Line[Idx])
                          Else
                            AddToResult(aChar(SP_SYMBOL) + Line[Idx]);
                    End Else
                      If Line[Idx] > #127 Then
                        AddToResult(aChar(SP_LITERAL_SYMBOL) + Line[Idx])
                      Else
                        AddToResult(aChar(SP_SYMBOL) + Line[Idx]);
                  Inc(Idx);
              End;

    End;

Finish:

  End;

  {$IFDEF FPC}
  Result := Copy(Result, 1, rPtr -1);
  {$ELSE}
  Result := Copy(Result, 1, NativeUInt(rPtr) - NativeUint(rStart));
  {$ENDIF}

End;

Function SP_IsConstant(Const Line: aString): Integer;
Var
  Idx, l: Integer;
  ss: aString;
Begin
  Result := -1;
  l := Length(Line);
  if l > 2 Then Begin
    if Line = 'TRUE' Then Begin
      Result := 0;
      Exit;
    End Else
      if Line = 'FALSE' Then Begin
        Result := 1;
        Exit;
      End Else Begin
        ss := Line[1] + Line[2];
        if (ss = 'KE') or (ss = 'FO') or (ss = 'DT') or (ss = 'tp') or (ss = 'nu') Then
          For Idx := 0 To High(SP_CONSTANTS) Do
            If Upper(SP_CONSTANTS[Idx].Name) = Line Then Begin
              Result := Idx;
              Exit;
            End;
      End;
  End;
End;

Function SP_SearchTokens(Const Line: aString): Integer;
var
  First, Last, Pivot: Integer;
  Found: Boolean;
begin
  Result := -1;
  if Not (Line[1] in ['A'..'Z']) Then Exit;
  First  := Hashes[Ord(Line[1]) - 65];
  Last   := Hashes[Ord(Line[1]) - 64] -1;
  if First = Last then Begin
    If SortedTokens[First].Name = Line then
      Result := SortedTokens[First].KeyWordID
  End Else Begin
    Found  := False;
    while (First <= Last) and (not Found) do begin
      Pivot := (First + Last) div 2;
      if SortedTokens[Pivot].Name = Line then begin
        Found  := True;
        Result := Pivot;
      end else
        if SortedTokens[Pivot].Name > Line then
          Last := Pivot - 1
        else
          First := Pivot + 1;
    end;
    If Result >= 0 Then
      Result := SortedTokens[Result].KeyWordID;
  End;
End;

Function  SP_IsReserved(Const Line: aString): Boolean;
Begin
  Result := SP_SearchTokens(Line) >= 0;
End;

Function SP_IsKeyWord(Const Line: aString): Integer;
Begin
  Result := SP_SearchTokens(Line);
  if (Result > -1) and (Result < SP_FUNCTION_BASE) Then
    Result := Result - SP_KEYWORD_BASE
  Else
    Result := -1;
End;

Function SP_IsFunction(Const Line: aString): Integer;
Begin
  Result := Max(SP_SearchTokens(Line) - SP_FUNCTION_BASE, -1);
End;

Function SP_GetNumber(Line: aString; Var Idx: Integer; Var Number: aFloat; AllowSpaces: Boolean): Boolean;
Var
  NegExp: Boolean;
  NumDigits: LongWord;
  OldIdx, NewIdx, c, l: Integer;
  Dec_Value, Dec_Count, Exponent: aFloat;
Begin

  // Returns a number from a String, at the supplied position.
  // Binary is prefixed by '%', Hex by '$' or '0x' and decimal has
  // no prefix.

  Result := False;
  Number := 0;
  l := Length(Line);

  If Line[Idx] = '%' Then Begin

    // Binary.

    Inc(Idx);
    OldIdx := Idx;
    NumDigits := 1;
    c := 0;
    While (Idx <= l) And (Line[Idx] in [' ', '1', '0']) Do Inc(Idx);
    If Idx > OldIdx Then Begin
      NewIdx := Idx;
      Dec(Idx);
      While Idx >= OldIdx Do Begin
        If Line[Idx] in ['0', '1'] Then Begin
          Result := True;
          If Line[Idx] = '1' Then
            Number := Number + NumDigits;
          Inc(c);
          if c > 32 Then Begin
            Result := False;
            Exit;
          End;
          Inc(NumDigits, NumDigits);
        End;
        Dec(Idx);
      End;
      Idx := NewIdx;
    End;

  End Else

    If (Line[Idx] = '$') or (Lower(Copy(Line, Idx, 2)) = '0x') Then Begin

      // Hex.

      Inc(Idx);
      If Idx <= l Then
        If Line[Idx] in ['x', 'X'] Then
          Inc(Idx);

      While (Idx <= l) and (Line[Idx] in ['0'..'9', 'A'..'F', 'a'..'f']) Do Begin
        If Line[Idx] <> ' ' Then
          Result := True;
        If Line[Idx] in ['A'..'F'] Then
          Number := (Number * 16) + Ord(Line[Idx]) - 55
        Else
          If Line[Idx] in ['a'..'f'] Then
            Number := (Number * 16) + Ord(Line[Idx]) - 87
          Else
            If Line[Idx] <> ' ' Then
              Number := (Number * 16) + Ord(Line[Idx]) - 48;
        Inc(Idx);
      End;

    End Else Begin

      // Decimal.

      While (Idx <= l) And (Line[Idx] in ['0'..'9']) Do Begin
        Result := True;
        Number := (Number * 10) + Ord(Line[Idx]) - 48;
        Inc(Idx);
      End;

      If Idx <= l Then Begin
        If Line[Idx] = '.' Then Begin
          Inc(Idx);
          Dec_Value := 0;
          Dec_Count := 10;
          While (Idx <= l) And (Line[Idx] in ['0'..'9']) Do Begin
            Result := True;
            Dec_Value := ((Ord(Line[Idx]) - 48) / Dec_Count) + Dec_Value;
            Dec_Count := Dec_Count * 10;
            Inc(Idx);
          End;
          If Dec_Value <> 0 Then
            Number := Number + Dec_Value;
        End;

        If Result And (Idx <= l) Then Begin
          If Line[Idx] in ['E','e'] Then Begin
            Inc(Idx);
            If Not (Line[Idx] in ['-', '+', '0'..'9']) Then  Begin
              Dec(Idx);
              Exit;
            End;
            Exponent := 0;
            NegExp := False;
            If Idx <= l Then
              If Line[Idx] in ['+', '-'] Then Begin
                If Line[Idx] = '-' Then NegExp := True;
                Inc(Idx);
              End;
            If (Idx <= l) And (Line[Idx] in ['0'..'9']) Then Begin
              While (Idx <= l) And (Line[Idx] in ['0'..'9']) Do Begin
                Exponent := (Exponent * 10) + Ord(Line[Idx]) - 48;
                Inc(Idx);
              End;
            End Else
              Result := False;
            If NegExp Then
              Number := Number / Power(10, Exponent)
            Else
              Number := Number * Power(10, Exponent);
          End;
        End;

      End;

    End;

End;

Function SP_Highlight(hlClr, NewWord, nClr: aString): aString;
Var
  Idx, wLen, LastSpace: Integer;
Begin

  Result := '';
  If NewWord <> '' Then Begin
    Idx := 1;
    Result := '';
    wLen := Length(NewWord);
    While Idx <= wLen Do Begin
      If NewWord[Idx] <> ' ' Then Begin
        Result := Result + hlClr;
        Break;
      End;
      Result := Result + ' ';
      Inc(Idx);
    End;
    LastSpace := wLen;
    While NewWord[LastSpace] = ' ' Do Dec(LastSpace);
    While Idx <= LastSpace Do Begin
      Result := Result + NewWord[Idx];
      Inc(Idx);
    End;
    Result := Result + nClr;
    While Idx <= wLen Do Begin
      Result := Result + ' ';
      Inc(Idx);
    End;
  End;

End;

Function SP_Detokenise(Tokens: aString; Var cPos: Integer; Highlight, UseDoubles: Boolean): aString;
Var
  Idx, Idx2, cIdx, Token, LastToken, LabelLen, lC: Integer;
  NewWord, Str, strClr, remClr, kwClr, nClr, numClr, vClr, ConstClr, Clr, BreakCharPre, BreakCharPost, Txt: aString;
  KeyWordID, LongWordPtr: pLongWord;
  LastChar: aChar;
  LastKeyWord: LongWord;
  FoundPos, FirstChar: Boolean;
Begin

  If Highlight Then Begin
    nClr := #16#17#0#0#0;
    kwClr := #16#0#0#0#0;
    numClr := #16#1#0#0#0;
    strClr := #16#1#0#0#0;
    vClr := #16#2#0#0#0;
    remClr := #16#32#0#0#0;
    constClr := #16#3#0#0#0;
  End Else Begin
    nClr := '';
    kwClr := '';
    numClr := '';
    vCLr := '';
    remClr := '';
    strClr := '';
    constClr := '';
  End;

  Idx := 1;
  LastToken := -1;
  Result := '';
  BreakCharPre := '';
  BreakCharPost := '';
  FirstChar := False;

  If Tokens[Idx] = aChar(SP_LINE_NUM) Then Begin
    Inc(Idx);
    Result := IntToString(pLongWord(@Tokens[Idx])^) + ' ';
    Inc(Idx, SizeOf(LongWord));
    FirstChar := True;
  End;

  If Tokens[Idx] = aChar(SP_LINE_LEN) Then
    Inc(Idx, SizeOf(LongWord) +1);

  If Tokens[Idx] = aChar(SP_STATEMENTS) Then
    Inc(Idx, 1 +((1 + pLongWord(@Tokens[Idx +1])^) * SizeOf(LongWord)));

  LastKeyWord := 0;
  FoundPos := False;

  While Idx <= Length(Tokens) Do Begin

    LastChar := #0;
    If Length(Result) > 0 Then Begin
      lC := Length(Result);
      While lC > 0 Do Begin
        If Result[lC] >= ' ' Then Begin
          LastChar := Result[lC];
          Break;
        End;
        Dec(lC);
      End;
    End;

    If (Not FoundPos) And (Idx >= cPos) Then Begin
      cPos := Length(Result) +1;
      FoundPos := True;
    End;

    Token := Ord(Tokens[Idx]);

    Case Token Of

      SP_STATEMENTS:
        Break;

      SP_LINE_LEN:
        Break;

      SP_LABEL:
        Begin
          Inc(Idx);
          LabelLen := pLongWord(@Tokens[Idx])^;
          Inc(Idx, SizeOf(LongWord));
          Result := Result + SP_Highlight(numClr, Copy(Tokens, Idx, LabelLen), nClr);
          Inc(Idx, LabelLen);
          LastKeyWord := 0;
        End;

      SP_COMMENT:
        Begin
          Inc(Idx);
          LabelLen := pLongWord(@Tokens[Idx])^;
          Inc(Idx, SizeOf(LongWord));
          Result := Result + SP_Highlight(remClr, '{'+Copy(Tokens, Idx, LabelLen)+'}', nClr);
          Inc(Idx, LabelLen);
          LastKeyWord := 0;
        End;

      SP_KEYWORD, SP_FUNCTION, SP_FUNCTION_EX:
        Begin
          Inc(Idx);
          KeyWordID := @Tokens[Idx];
          LastKeyWord := KeyWordID^;
          { fix for legacy programs that use FN and POINT }
            If Ord(Tokens[Idx -1]) = SP_FUNCTION_EX Then
              Tokens[Idx -1] := aChar(SP_FUNCTION);
            If KeyWordID^ = 3000 Then KeyWordID^ := SP_FN_POINT;
            If KeyWordID^ = 3001 Then KeyWordID^ := SP_FN_FN;
          { End fix}
          If Highlight Then Begin
            BreakCharPre := '';
            BreakCharPost := '';
            If KeyWordID^ = SP_KW_THEN Then Begin
              BreakCharPre := '';
              BreakCharPost := #13;
            End;
            If KeyWordID^ = SP_KW_ELSE Then Begin
              BreakCharPre := #13;
              BreakCharPost := #13;
            End;
          End;
          If Ord(Tokens[Idx -1]) = SP_KEYWORD Then Begin
            FirstChar := False;
            If Integer(KeyWordID^) - SP_KEYWORD_BASE <= Length(SP_KEYWORDS_EXTRA) Then
              NewWord := SP_KEYWORDS_EXTRA[KeyWordID^ - SP_KEYWORD_BASE]
            Else
              NewWord := ' ';
            If NewWord = ' s** ' Then
              NewWord := ' SUB ';
          End Else
            If Ord(Tokens[Idx -1]) = SP_FUNCTION Then
              NewWord := Copy(SP_FUNCTIONS_EXTRA[KeyWordID^ - SP_FUNCTION_BASE], 2, 999);
          If NewWord <> '' Then
            If NewWord[1] = ' ' Then
              If (Result <> '') And (Result[Length(Result)] = ' ') Then
                NewWord := Copy(NewWord, 2, Length(NewWord));
          If (Length(Result) > 0) And (LastChar in ['0'..'9', 'A'..'Z', 'a'..'z', ':', ')']) And
             (LastChar <> ' ') And ((NewWord <> '') And (NewWord[1] <> ' ')) Then
            Result := Result + ' ' + BreakCharPre + SP_Highlight(kwClr, NewWord, nClr) + BreakCharPost
          Else
            Result := Result + BreakCharPre + SP_Highlight(KwClr, NewWord, nClr) + BreakCharPost;
          Inc(Idx, SizeOf(LongWord));
          LastChar := NewWord[Length(NewWord)];
          If KeyWordID^ = SP_KW_REM Then Begin
            If  LastChar = ' ' Then
              Result := Copy(Result, 1, Length(Result) -1);
            If Byte(Tokens[Idx]) = SP_TEXT Then Inc(Idx, 1 + SizeOf(LongWord));
            Result := Result + SP_Highlight(remClr, Copy(Tokens, Idx, Length(Tokens)), nClr);
            If Pos(#255, Result) > 0 Then
              Result := Copy(Result, 1, Pos(#255, Result) -1);
            Break;
          End;
        End;

      SP_VALUE:
        Begin
          If UseDoubles Then
            Inc(Idx, SizeOf(Double) +1)
          Else
            Inc(Idx, SizeOf(aFloat)+1);
          If LastToken in [SP_KEYWORD, SP_FUNCTION] Then
            If LastChar <> ' ' Then
              Result := Result + ' ';
          LastKeyWord := 0;
        End;

      SP_VALUE10:
        Begin
          Inc(Idx, 11);
          LastKeyWord := 0;
        End;

      SP_STRING:
        Begin
          Inc(Idx);
          LongWordPtr := @Tokens[Idx];
          Inc(Idx, SizeOf(LongWord));
          Str := '';
          Idx2 := Idx;
          While LongWord(Idx2) < LongWord(Idx) + LongWordPtr^ Do Begin
            If Tokens[Idx2] = '"' Then
              Str := Str + '""'
            Else
              Str := Str + Tokens[Idx2];
            Inc(Idx2);
          End;
          Result := Result + SP_Highlight(strClr, '"'+Str+'"', nClr);
          Inc(Idx, LongWordPtr^);
          LastKeyWord := 0;
        End;

      SP_STRINGCHAR:
        Begin
          Result := Result + '#';
          If UseDoubles Then
            Inc(Idx, SizeOf(Double)+1)
          Else
            Inc(Idx, SizeOf(aFloat)+1);
          LastKeyWord := 0;
        End;

      SP_NUMVAR:
        Begin
          pLongWord(@Tokens[Idx +1])^ := 0;
          Inc(Idx, 1 + SizeOf(LongWord));
          LongWordPtr := @Tokens[Idx];
          Inc(Idx, SizeOf(LongWord));
          NewWord := Copy(Tokens, Idx, LongWordPtr^);
          If NewWord[1] = '!' Then
            NewWord := Copy(NewWord, 2, Length(NewWord));
          If LastChar in ['a'..'z', 'A'..'Z', '0'..'9', ':'] Then
            NewWord := ' ' + NewWord;
          Result := Result + SP_Highlight(vClr, NewWord, nClr);
          Inc(Idx, LongWordPtr^);
          LastKeyWord := 0;
        End;

      SP_STRVAR:
        Begin
          pLongWord(@Tokens[Idx +1])^ := 0;
          Inc(Idx, 1 + SizeOf(LongWord));
          LongWordPtr := @Tokens[Idx];
          Inc(Idx, SizeOf(LongWord));
          NewWord := Copy(Tokens, Idx, LongWordPtr^);
          If NewWord[1] = '!' Then
            NewWord := Copy(NewWord, 2, Length(NewWord));
          If LastChar in ['a'..'z', 'A'..'Z', '0'..'9', ':'] Then
            NewWord := ' ' + NewWord;
          Result := Result + SP_Highlight(vClr, NewWord + '$', nClr);
          Inc(Idx, LongWordPtr^);
          LastKeyWord := 0;
        End;

      SP_TEXT, SP_STRUCT_MEMBER_N, SP_STRUCT_MEMBER_S:
        Begin
          Inc(Idx);
          LongWordPtr := @Tokens[Idx];
          Inc(Idx, SizeOf(LongWord));
          Txt := Copy(Tokens, Idx, LongWordPtr^);
          Clr := nClr;
          If Token in [SP_STRUCT_MEMBER_N, SP_STRUCT_MEMBER_S] Then
            Result := Result + '.'
          Else Begin
            cIdx := 0;
            While cIdx < Length(SP_Constants) -1 Do Begin
              If SP_Constants[cIdx].Name = Txt Then Begin
                Clr := ConstClr;
                Break;
              End;
              Inc(cIdx);
            End;
          End;
          Result := Result + SP_Highlight(Clr, Txt, nClr);
          Inc(Idx, LongWordPtr^);
          LastKeyWord := 0;
        End;

      SP_LITERAL_SYMBOL:
        Begin
          Inc(Idx);
          Result := Result + aChar(Tokens[Idx]);
          LastKeyWord := 0;
          Inc(Idx);
        End;

      SP_SYMBOL:
        Begin
          Inc(Idx);
          Case Tokens[Idx] of
            SP_CHAR_GTE: NewWord := '>=';
            SP_CHAR_LTE: NewWord := '<=';
            SP_CHAR_DNE: NewWord := '<>';
            SP_CHAR_AND: NewWord := ' AND ';
            SP_CHAR_OR:  NewWord := ' OR ';
            SP_CHAR_MOD: NewWord := ' MOD ';
            SP_CHAR_XOR: NewWord := ' XOR ';
            SP_CHAR_SHL: NewWord := ' SHL ';
            SP_CHAR_SHR: NewWord := ' SHR ';
            SP_CHAR_ADD: NewWord := ' ADD ';
            SP_CHAR_SUB: NewWord := ' SUB ';
            SP_CHAR_MUL: NewWord := ' MUL ';
            SP_CHAR_DIV: NewWord := ' DIV ';
            SP_CHAR_INCVAR: NewWord := '+=';
            SP_CHAR_DECVAR: NewWord := '-=';
            SP_CHAR_MULVAR: NewWord := '*=';
            SP_CHAR_DIVVAR: NewWord := '/=';
            SP_CHAR_POWVAR: NewWord := '^=';
            SP_CHAR_MODVAR: NewWord := '%=';
            SP_CHAR_ANDVAR: NewWord := '&=';
            SP_CHAR_ORVAR:  NewWord := '|=';
            SP_CHAR_NOTVAR: NewWord := '!=';
            SP_CHAR_XORVAR: NewWord := '~=';
            SP_CHAR_NOT: NewWord := 'NOT ';
            SP_CHAR_EQV: NewWord := ' EQV ';
            SP_CHAR_IMP: NewWord := ' IMP ';
            '&': NewWord := '&';
            '|': NewWord := '|';
            '(':
              Begin
                If Length(Result) > 0 Then Begin
                  If (LastChar = ' ') And (Not (LastKeyWord < SP_FUNCTION_BASE) And (Not (Result[Length(Result)-1] in ['A'..'Z'])) or (LastKeyWord >= SP_FUNCTION_BASE)) Then
                    Result := Copy(Result, 1, Length(Result) -1) + '('
                  Else
                    Result := Result + '(';
                End Else
                    Result := Result + '(';
                NewWord := '';
              End;
            ':':
              Begin
                If Not FirstChar Then
                  While (Copy(Result, Length(Result), 1) <= ' ') And (Result <> '') Do
                    Result := Copy(Result, 1, Length(Result) -1);
                FirstChar := False;
                Result := Result + ':';
                NewWord := '';
              End;
            SP_CHAR_SEMICOLON:
              Begin
                Result := Result + ';';
                NewWord := '';
              End;
            ')':
              Begin
                If Length(Result) > 0 Then Begin
                  If (LastChar = ' ') And (NewWord[Length(NewWord)-1] in ['A'..'Z']) And (NewWord <> ' TO ') Then
                    Result := Copy(Result, 1, Length(Result) -1) + ')'
                  Else
                    Result := Result + ')';
                End Else
                    Result := Result + ')';
                NewWord := '';
              End;
            '?':
              If LastChar <> '' Then Begin
                If Result[Length(Result)] <= ' ' Then
                  Result := Result + '?'
                Else
                  Result := Result + ' ?';
                If (NewWord = ' THEN ') or (NewWord = ' ELSE ') Then NewWord := '';
              End Else
                Result := Result + '?';
          Else
            Result := Result + Tokens[Idx];
            NewWord := '';
          End;
          Inc(Idx);
          If NewWord <> '' Then Begin
            If NewWord[1] = ' ' Then
              If (Result = '') or (Result[Length(Result)] = ' ') Then
                NewWord := Copy(NewWord, 2, Length(NewWord));
            Result := Result + NewWord;
          End;
          LastKeyWord := 0;
        End;

      SP_TERMINAL:
        Begin
          If Not FoundPos Then
            If cPos < Length(Tokens) Then
              cPos := Length(Result)
            Else
              cPos := cPos - Length(Tokens);
          Exit;
        End;

    Else

      Idx := Length(Tokens);

    End;

    LastToken := Token;

  End;

  If Not FoundPos Then
    If cPos < Length(Tokens) Then
      cPos := Length(Result)
    Else
      cPos := cPos - Length(Tokens);

End;

Function CondenseString(const Text: aString): aString;
Var
  c: aChar;
  s: aString;
  i, l: Integer;
  lastPaper, lastInk, lastItalic, lastBold,
  curPaper, curInk, curItalic, curBold: Integer;
Begin

  // The syntax highlighter can get quite silly with the amount of colour codes it adds in.
  // This keeps track of them and replaces blocks of them with the last ink/paper/italic/bold codes used.

  lastPaper := -1; curPaper := -1;
  lastInk := -1; curInk := -1;
  lastItalic := -1; curItalic := -1;
  lastBold := -1; curBold := -1;

  Result := '';
  i := 1;
  l := Length(Text);

  While i < L Do Begin
    c := Text[i];
    If (c < ' ') And (c <> #5) Then Begin
      Case c of
        #16: // Ink
          Begin
            curInk := pLongWord(@Text[i+1])^;
          End;
        #17: // Paper
          Begin
            curPaper := pLongWord(@Text[i+1])^;
          End;
        #26: // Italic
          Begin
            curItalic := pLongWord(@Text[i+1])^;
          End;
        #27: // Bold
          Begin
            curBold := pLongWord(@Text[i+1])^;
          End;
      End;
      Inc(i, 5);
    End Else Begin
      If (curInk >= 0) And (curInk <> lastInk) Then s := #16 + LongWordToString(curInk) Else s := '';
      If (curPaper >= 0) And (curPaper <> lastPaper) Then s := s + #17 + LongWordToString(curPaper);
      If (curItalic >= 0) And (curItalic <> lastItalic) Then s := s + #26 + LongWordToString(curItalic);
      If (curBold >= 0) And (curBold <> lastBold) Then s := s + #27 + LongWordToString(curBold);
      lastInk := curInk;
      lastPaper := curPaper;
      lastItalic := curItalic;
      lastBold := curBold;
      Result := Result + s + c;
      Inc(i);
      If c = #5 Then Begin
        Result := Result + Text[i];
        Inc(i);
      End;

    End;
  End;

  If (curInk >= 0) And (curInk <> lastInk) Then s := #16 + LongWordToString(curInk) Else s := '';
  If (curPaper >= 0) And (curPaper <> lastPaper) Then s := s + #17 + LongWordToString(curPaper);
  If (curItalic >= 0) And (curItalic <> lastItalic) Then s := s + #26 + LongWordToString(curItalic);
  If (curBold >= 0) And (curBold <> lastBold) Then s := s + #27 + LongWordToString(curBold);

  If s <> '' Then
    Result := Result + s;

End;

Function SP_SyntaxHighlight(CodeLine, PrevSyntax: aString; HasNumber: Boolean; Var AddedChars: Integer): aString;
Var

  Idx, l, l1, Idx2, sIdx: Integer;
  Wd, LastSyntax, NewSyntax, Tw: aString;
  Valid, AddSpace, IsREM, StringDone: Boolean;
  Ch, Ch1: aChar;

Const

  Compounds: Array[0..9, 0..1] of aString =
    (('DEFPROC', 'DEF PROC'),
     ('DEFFN', 'DEF FN'),
     ('DEFSTRUCT', 'DEF STRUCT'),
     ('ENDPROC', 'END PROC'),
     ('ENDIF', 'END IF'),
     ('ENDSTRUCT', 'END STRUCT'),
     ('EXITPROC', 'EXIT PROC'),
     ('ENDCASE', 'END CASE'),
     ('GOTO', 'GO TO'),
     ('GOSUB', 'GO SUB'));

Label

  ProcessString;

Begin

  // Provides syntax highlighting for the new editor, and preserves code style.

  Result := '';
  LastSyntax := '';
  AddedChars := 0;
  IsREM := False;
  StringDone := False;
  AddSpace := False;

  // Highlight the line number.

  Idx := 1;
  COdeLine := InsertLiterals(CodeLine);
  l := Length(CodeLine);
  If HasNumber Then Begin
    wd := '';
    While CodeLine[Idx] <= ' ' Do Inc(Idx);
    If Idx <= l Then
      While (Idx <= l) And (CodeLine[Idx] in ['0'..'9']) Do Begin
        wd := wd + CodeLine[Idx];
        Inc(Idx);
      End;
    Result := Result + LinClr + Wd;
    LastSyntax := LinClr;
  End Else Begin
    Result := PrevSyntax;
    If PrevSyntax = remClr Then Begin
      Result := CondenseString(Result + CodeLine + PrevSyntax);
      Exit;
    End Else
      If PrevSyntax = StrClr Then Begin
        Idx2 := 1;
        Goto ProcessString;
      End;
  End;
  Wd := '';

  // Now get tokens one at a time. Alphanumeric, numeric, symbol.

  While Idx <= l Do Begin

    NewSyntax := '';
    AddSpace := False;

    // Now start to gather up characters for the current token.

    If CodeLine[Idx] in ['a'..'z', 'A'..'Z'] Then Begin
      // Starts with a letter, has to be alphanumeric with optional $ suffix.
      sIdx := Idx;
      While (Idx <= l) And (CodeLine[Idx] in ['_', 'A'..'Z', 'a'..'z', '0'..'9']) Do Begin
        Wd := Wd + CodeLine[Idx];
        Inc(Idx);
      End;
      // Variables and some functions can have a $ suffix
      If (Idx <= l) And (CodeLine[Idx] = '$') Then Begin
        Wd := Wd + '$';
        Inc(Idx);
      End;
      // Now Wd contains our token. It may be a function or keyword, it may be a variable name, and Idx is ready for the next loop.
      // So test - what is it? Is it a contracted compound like GOTO which expands to GO TO?
      For Idx2 := 0 To High(Compounds) Do Begin
        L1 := Length(Compounds[Idx2, 0]);
        If Upper(Copy(Wd, 1, L1)) = Compounds[Idx2, 0] Then Begin
          Wd := Copy(Wd, 1, Pos(' ', Compounds[Idx2, 1]) -1);
          Idx := sIdx + Length(Wd);
          AddSpace := True;
          Inc(AddedChars);
          Break;
        End;
      End;
      // Finally, we now run through our tests to determine if it's a keyword or function.
      Tw := Upper(Wd);
      Idx2 := SP_IsKeyWord(Tw);
      If Idx2 > -1 Then Begin
        If Idx2 + SP_KEYWORD_BASE = SP_KW_REM Then Begin
          NewSyntax := kwdClr;
          Wd := Tw + remClr;
          Wd := Wd + Copy(CodeLine, Idx);
          IsREM := True;
          Idx := L +1;
        End Else Begin
          NewSyntax := kwdClr;
          Wd := Tw;
        End;
      End Else
        If SP_IsFunction(Tw) > -1 Then Begin
          NewSyntax := fnClr;
          Wd := Tw;
        End Else
          If SP_IsConstant(Tw) > -1 Then Begin
            NewSyntax := constClr;
          End Else
            If Tw = 'END' Then Begin
              NewSyntax := kwdClr; // END is not a keyword, but is part of END PROC etc
              Wd := Tw;
            End Else
              // It's not a keyword, a function or a constant. Could be... A Variable! W00t!
              If Wd[Length(Wd)] = '$' Then
                NewSyntax := svClr
              Else
                NewSyntax := nvClr;
    End Else
      If CodeLine[Idx] in ['%', '$', '.', '0'..'9'] Then Begin
        // Number - Hex, Binary, Decimal, Any base. May be of the form:
        // .xxx, xE+xx, $xx, %xx, xxx\xx, xx.xxx etc.
        Valid := False;
        If CodeLine[Idx] = '%' Then Begin
          // Binary
          Wd := '%';
          Inc(Idx);
          While (Idx <= L) And (CodeLine[Idx] in ['0'..'1']) Do Begin
            Wd := Wd + CodeLine[Idx];
            Valid := True;
            Inc(Idx);
          End;
          If Valid Then
            NewSyntax := binClr
          Else
            NewSyntax := noClr;
        End Else
          If (CodeLine[Idx] = '$') or (Lower(Copy(CodeLine, Idx, 2)) = '0x') Then Begin
            // Hex
            If CodeLine[Idx] = '$' Then Begin
              Wd := '$';
              Inc(Idx);
            End Else Begin
              Wd := '0x';
              Inc(Idx, 2);
            End;
            While (Idx <= L) And (CodeLine[Idx] in ['0'..'9', 'A'..'Z', 'a'..'z']) Do Begin
              Wd := Wd + Upper(CodeLine[Idx]);
              Valid := True;
              Inc(Idx);
            End;
            If Valid Then
              NewSyntax := hexClr
            Else
              NewSyntax := noClr;
          End Else Begin
            // Regular number for now. If a backslash occurs, it's a based number, with a radix to follow.
            // If an E happens, it's Scientific.
            While (Idx <= L) And (CodeLine[Idx] in ['0'..'9']) Do Begin
              Wd := Wd + CodeLine[Idx];
              Valid := True;
              Inc(Idx);
            End;
            If (Idx <= L) And (CodeLine[Idx] = '.') Then Begin
              Wd := Wd + '.'; Inc(Idx);
              Valid := False;
              While (Idx <= L) And (CodeLine[Idx] in ['0'..'9']) Do Begin
                Wd := Wd + CodeLine[Idx];
                Valid := True;
                Inc(Idx);
              End;
              If (Idx <= L) And (CodeLine[Idx] in ['E', 'e']) Then Begin
                Wd := Wd + Upper(CodeLine[Idx]);
                Valid := False;
                Inc(Idx);
                If (Idx <= L) And (CodeLine[Idx] in ['+', '-']) Then Begin
                  Wd := Wd + CodeLine[Idx];
                  Inc(Idx);
                End;
                While (Idx <= L) And (CodeLine[Idx] in ['0'..'9']) Do Begin
                  Wd := Wd + CodeLine[Idx];
                  Valid := True;
                  Inc(Idx);
                End;
              End;
            End Else
              If (Idx <= L) And (CodeLine[Idx] = '\') Then Begin
                Wd := Wd + '\';
                Valid := False;
                Inc(Idx);
                While (Idx <= L) And (CodeLine[Idx] in ['0'..'9']) Do Begin
                  Wd := Wd + CodeLine[Idx];
                  Valid := True;
                  Inc(Idx);
                End;
                NewSyntax := '';
              End Else
                If (Idx <= L) And (CodeLine[Idx] in ['E', 'e']) Then Begin
                  Wd := Wd + Upper(CodeLine[Idx]);
                  Valid := False;
                  Inc(Idx);
                  If (Idx <= L) And (CodeLine[Idx] in ['+', '-']) Then Begin
                    Wd := Wd + CodeLine[Idx];
                    Inc(Idx);
                  End;
                  While (Idx <= L) And (CodeLine[Idx] in ['0'..'9']) Do Begin
                    Wd := Wd + CodeLine[Idx];
                    Valid := True;
                    Inc(Idx);
                  End;
                End;
            If Valid Then Begin
              If NewSyntax = '' Then
                NewSyntax := baseClr
              Else
                NewSyntax := numClr;
            End Else
              // This is an unfinished number, so no highlighting.
              NewSyntax := noClr;
          End;
      End Else Begin
        // Something else. Maybe a symbol. Maybe just whitespace. Strings start with " characters or a # character.
        If CodeLine[Idx] <= ' ' Then Begin
          While (Idx <= L) And (CodeLine[Idx] <= ' ') Do Begin
            Wd := Wd + CodeLine[Idx];
            Inc(Idx);
          End;
          NewSyntax := noClr;
        End Else Begin
          // A Symbol, then.
          Ch := CodeLine[Idx];
          Idx2 := 1;
          If Idx < L Then
            Ch1 := CodeLine[Idx +1]
          Else
            Ch1 := #0;
          If Ch in ['<', '>'] Then Begin
            If Ch1 = '=' Then Begin
              NewSyntax := relClr;
              Idx2 := 2;
            End Else
              If (Ch = '<') And (Ch1 = '>') Then Begin
                NewSyntax := relClr;
                Idx2 := 2;
              End Else
                NewSyntax := relClr;
          End Else
            If Ch in ['+', '-', '*', '/', '^', '%', '&', '|', '~'] Then Begin
              If Ch1 = '=' Then Begin
                NewSyntax := mathClr;
                Idx2 := 2;
              End Else
                NewSyntax := mathClr;
            End Else
              If Ch = '@' Then Begin // Label
                Idx2 := Idx +1;
                While (Idx2 <= L) And (CodeLine[Idx2] in ['0'..'9', '_', 'A'..'Z', 'a'..'z']) Do
                  Inc(Idx2);
                Dec(Idx2, Idx);
                NewSyntax := labClr;
              End Else
                If Ch = '{' Then Begin
                  Idx2 := Idx +1;
                  While (Idx2 <= L) And (CodeLine[Idx2] <> '}') Do
                    Inc(Idx2);
                  Dec(Idx2, Idx -1);
                  NewSyntax := RemClr;
                End Else
                  If CodeLine[Idx] = '"' Then Begin // String constant
                    Idx2 := Idx +1;
                    StringDone := False;
                    ProcessString:
                    While (Idx2 <= L) Do Begin
                      If CodeLine[Idx2] = '"' Then Begin
                        StringDone := True;
                        If Idx2 < L Then
                          If CodeLine[Idx2 +1] <> '"' Then
                            Break
                          Else
                            Inc(Idx2);
                      End;
                      Inc(Idx2);
                    End;
                    Dec(Idx2, Idx -1);
                    NewSyntax := StrClr;
                  End Else
                    If Ch = '=' Then Begin
                      NewSyntax := relClr
                    End Else
                      If Ch in ['(', ')', '[', ']'] Then Begin
                        NewSyntax := BraceClr;
                      End Else
                        If Ch = '#' Then Begin
                          Idx2 := Idx +1;
                          NewSyntax := symClr;
                          If Idx2 <= L Then
                            If Copy(CodeLine, Idx2, 2) = '0x' Then Begin
                              Inc(Idx2, 2); sIdx := Idx2;
                              While (Idx2 <= L) And (CodeLine[Idx2] in ['0'..'9', 'a'..'f', 'A'..'F']) Do
                                Inc(Idx2);
                              If Idx2 < sIdx Then NewSyntax := strClr;
                            End Else
                              If CodeLine[Idx2] in ['0'..'9'] Then Begin
                                While (Idx2 <= L) And (CodeLine[Idx2] in ['0'..'9']) Do
                                  Inc(Idx2); sIdx := Idx2;
                                If Idx2 < sIdx Then NewSyntax := strClr;
                              End Else
                                If CodeLine[Idx2] = '%' Then Begin
                                  Inc(Idx2); sIdx := Idx2;
                                  While (Idx2 <= L) And (CodeLine[Idx2] in ['0', '1']) Do
                                    Inc(Idx2);
                                  If Idx2 < sIdx Then NewSyntax := strClr;
                                End Else
                                  If CodeLine[Idx2] = '$' Then Begin
                                    Inc(Idx2); sIdx := Idx2;
                                    While (Idx2 <= L) And (CodeLine[Idx2] in ['0'..'9', 'a'..'f', 'A'..'F']) Do
                                      Inc(Idx2);
                                    If Idx2 < sIdx Then NewSyntax := strClr;
                                  End;
                        Dec(Idx2, Idx );
                      End Else
                        NewSyntax := symClr;
          Wd := Copy(CodeLine, Idx, Idx2);
          Inc(Idx, Idx2);
        End;
      End;

    If LastSyntax <> NewSyntax Then
      Result := Result + NewSyntax;
    If (NewSyntax = StrClr) And StringDone Then
      LastSyntax := NoClr
    Else
      LastSyntax := NewSyntax;
    Result := Result + wd;
    If AddSpace Then
      Result := Result + ' ';
    Wd := ''

  End;

  If IsREM Then
    Result := Result + remClr
  Else
    Result := Result + LastSyntax;

  Result := CondenseString(Result);

End;

Function SP_Store_Line(Tokens: aString): Integer;
Var
  LineNum: LongWord;
  Idx, LineIdx, Position: Integer;
Begin

  // Stores a line in the SP_Program list. First, get the line number:

  LineNum := pLongWord(@Tokens[2])^;
  Position := 3 + SizeOf(LongWord);

  // Now skip the statements list.

  Inc(Position, (1 + pLongWord(@Tokens[Position])^) * SizeOf(LongWord));

  If Tokens[Position] = SP_TERMINAL_CHAR Then Begin

    // Delete operation

    Idx := SP_FindLine(LineNum, True);
    If Idx <> -1 Then Begin
      SP_Program_Delete(Idx);
      LineIdx := SP_FindLine(PROGLINE, True);
      If LineIdx > -1 Then Begin
        If LineIdx < SHOWLINE Then SHOWLINE := pLongWord(@SP_Program[LineIdx][2])^;
        PROGLINE := pLongWord(@SP_Program[LineIdx][2])^;
      End;
    End;

  End Else Begin

    Idx := 0;
    While (Idx < SP_Program_Count) And (pLongWord(@SP_Program[Idx][2])^ < LineNum) Do
      Inc(Idx);

    If Idx = SP_Program_Count Then
      SP_Program_Add(Tokens)
    Else
      If LineNum = pLongWord(@SP_Program[Idx][2])^ Then
        SP_Program[Idx] := Tokens
      Else
        SP_Program_Insert(Idx, Tokens);

  End;

  PROGCHANGED := True;
  Result := LINENUM;

End;

// String array handlers

Procedure SP_Program_Add(Str: aString);
Begin
  Inc(SP_Program_Count);
  SetLength(SP_Program, SP_Program_Count);
  SP_Program[SP_Program_Count -1] := Str;
  PROGCHANGED := True;
End;

Procedure SP_Program_AddStrings(List: TAnsiStringList);
Var
  Idx: Integer;
Begin
  For Idx := 0 To List.Count -1 Do
    SP_Program_Add(aString(List[Idx]));
  PROGCHANGED := True;
End;

Procedure SP_Program_AddStringsArray(Var List: Array of aString);
Var
  Idx: Integer;
Begin
  For Idx := 0 To Length(List) -1 Do
    SP_Program_Add(List[Idx]);
  PROGCHANGED := True;
End;

Procedure SP_Program_Insert(Index: Integer; Str: aString);
Var
  Idx: Integer;
Begin
  Inc(SP_Program_Count);
  SetLength(SP_Program, SP_Program_Count);
  For Idx := SP_Program_Count -1 DownTo Index +1 Do
    SP_Program[Idx] := SP_Program[Idx -1];
  SP_Program[Index] := Str;
  PROGCHANGED := True;
End;

Procedure SP_Program_Delete(Index: Integer);
Var
  Idx: Integer;
Begin
  For Idx := Index To SP_Program_Count -2 Do
    SP_Program[Idx] := SP_Program[Idx +1];
  Dec(SP_Program_Count);
  SetLength(SP_Program, SP_Program_Count);
  PROGCHANGED := True;
End;

Procedure SP_Program_Delete_Line(Line: Integer);
Begin

  Line := SP_FindLine(Line, True);
  If Line >= 0 Then SP_Program_Delete(Line);

End;

Procedure SP_Program_Clear;
Begin
  SetLength(SP_Program, 0);
  SP_Program_Count := 0;
  SP_DeleteIncludes;
  PROGCHANGED := True;
End;

Procedure SP_MakeKeywordLUT;
Var
  i, j, numTokens: Integer;

  procedure Sort(Start, Stop: Integer);
  var
    Left, Right, Mid: Integer;
    Pivot, Temp: TCompoundWord;
  begin
    Left  := Start;
    Right := Stop;
    Mid   := (Start + Stop) div 2;
    Pivot := SortedTokens[mid];
    repeat
      while SortedTokens[Left].Name < Pivot.Name do Inc(Left);
      while Pivot.Name < SortedTokens[Right].Name do Dec(Right);
      if Left <= Right then begin
        Temp                := SortedTokens[Left];
        SortedTokens[Left]  := SortedTokens[Right];
        SortedTokens[Right] := Temp;
        Inc(Left);
        Dec(Right);
      end;
    until Left > Right;
    if Start < Right then Sort(Start, Right);
    if Left < Stop then Sort(Left, Stop);
  end;

Begin

  j := 0;
  numTokens := Length(SP_KEYWORDS_EXTRA) + Length(SP_FUNCTIONS_EXTRA);
  SetLength(SortedTokens, numTokens);
  For i := 0 To Length(SP_KEYWORDS_EXTRA) -1 Do
    With SortedTokens[j] Do Begin
      Name := Upper(StripSpaces(SP_KEYWORDS[i]));
      KeyWordID := i + SP_KEYWORD_BASE;
      Inc(j);
    End;
  For i := 0 To Length(SP_FUNCTIONS_EXTRA) -1 Do
    With SortedTokens[j] Do Begin
      Name := Upper(Copy(StripSpaces(SP_FUNCTIONS_EXTRA[i]), 2));
      KeyWordID := i + SP_FUNCTION_BASE;
      Inc(j);
    End;

  Sort(0, High(SortedTokens));

  For i := 0 to 25 Do
    Hashes[i] := -1;

  For j := 0 To 25 Do
    For i := 0 to numTokens -1 Do
      if SortedTokens[i].Name[1] = aChar(65 + j) Then Begin
        Hashes[j] := i;
        Break;
      End;
  Hashes[26] := numTokens;

End;

Initialization

  SetLength(SP_KEYWORDS, High(SP_KEYWORDS_EXTRA) +1);
  For Idx_t := 0 To High(SP_KEYWORDS_EXTRA) Do Begin

    TempStr := SP_KEYWORDS_EXTRA[Idx_t];
    If TempStr[1] = ' ' Then TempStr := Copy(TempStr, 2, Length(TempStr));
    If TempStr[Length(TempStr)] = ' ' Then TempStr := Copy(TempStr, 1, Length(TempStr) -1);

    SP_KEYWORDS[Idx_t] := TempStr;

  End;

  SetLength(SP_FUNCTIONS, High(SP_FUNCTIONS_EXTRA) +1);
  SetLength(SP_OPTIMISE_FLAGS, Length(SP_FUNCTIONS));
  SetLength(SP_OPTIMISE_META_FLAGS, Length(SP_FUNCTION_NAMES));

  For Idx_t := 0 To High(SP_FUNCTIONS_EXTRA) Do Begin

    TempStr := SP_FUNCTIONS_EXTRA[Idx_t];
    If TempStr[1] = 'o' Then SP_OPTIMISE_FLAGS[Idx_t] := True Else SP_OPTIMISE_FLAGS[Idx_t] := False;
    TempStr := Copy(TempStr, 2, Length(TempStr));
    If TempStr[1] = ' ' Then TempStr := Copy(TempStr, 2, Length(TempStr));
    If TempStr[Length(TempStr)] = ' ' Then TempStr := Copy(TempStr, 1, Length(TempStr) -1);

    SP_FUNCTIONS[Idx_t] := TempStr;

  End;

  For Idx_t := 0 To High(SP_FUNCTION_NAMES) Do Begin

    TempStr := SP_FUNCTION_NAMES[Idx_t];
    If TempStr[1] = 'o' Then SP_OPTIMISE_META_FLAGS[Idx_t] := True Else SP_OPTIMISE_META_FLAGS[Idx_t] := False;
    TempStr := Copy(TempStr, 2, Length(TempStr));
    If TempStr[1] = ' ' Then TempStr := Copy(TempStr, 2, Length(TempStr));
    If TempStr[Length(TempStr)] = ' ' Then TempStr := Copy(TempStr, 1, Length(TempStr) -1);

  End;

  SP_MakeKeywordLUT;

Finalization

  While InterpreterThreadAlive Do
    CB_YIELD;

end.
