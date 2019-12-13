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

unit SP_Errors;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

interface

Uses SP_Util;

Type

  TSP_ErrorCode = Packed Record
    Line,
    Statement,
    Position,
    TokenPos,
    Code,
    ReturnType: Integer;
    Pointer: Pointer;
  End;
  pSP_ErrorCode = ^TSP_ErrorCode;

Const

  // Syntax error codes - direct commands.

  SP_ERR_NO_ERROR = 999;
  SP_ERR_OK = 0;
  SP_ERR_MISSING_NUMEXPR = 1;
  SP_ERR_MISSING_BRACKET = 2;
  SP_ERR_MISSING_OPERATOR = 3;
  SP_ERR_ILLEGAL_CHAR = 4;
  SP_ERR_UNHANDLED_FUNCTION = 5;
  SP_ERR_MISSING_STREXPR = 6;
  SP_ERR_INVALID_KEYWORD = 7;
  SP_ERR_MISSING_COMMA = 8;
  SP_ERR_MISSING_VAR = 9;
  SP_ERR_MISSING_EQU = 10; // A
  SP_ERR_INTEGER_OUT_OF_RANGE = 11; // B
  SP_ERR_BAD_SLICER = 12; // C
  SP_ERR_SUBSCRIPT_WRONG = 13; // D
  SP_ERR_ARRAY_NOT_FOUND = 14; // E
  SP_ERR_INVALID_NUMEXPR = 15; // F
  SP_ERR_BREAK = 16; // G
  SP_ERR_BAD_GO = 17; // H
  SP_ERR_RETURN_WITHOUT_GOSUB = 18; // I
  SP_ERR_STOP = 19; // J
  SP_ERR_MISSING_VARIABLE = 20; // K
  SP_ERR_MISSING_TO = 21; // L
  SP_ERR_STEP_EXPECTED = 22; // M
  SP_ERR_NEXT_WITHOUT_FOR = 23; // N;
  SP_ERR_INVALID_COLOUR_ITEM = 24; // O
  SP_ERR_MISSING_THEN = 25; // P
  SP_ERR_MIXED_TYPES = 26; // Q
  SP_ERR_SYNTAX_ERROR = 27; // R
  SP_ERR_SAVE_ERROR = 28; // S
  SP_ERR_SAVE_OPEN_ERROR = 29; // T
  SP_ERR_FILE_MISSING = 30; // U
  SP_ERR_FILE_CORRUPT = 31; // V
  SP_ERR_LOOP_WITHOUT_DO = 32; // W
  SP_ERR_WHILE_WITHOUT_LOOP = 33; // X
  SP_ERR_EXIT_WITHOUT_LOOP = 34; // Y
  SP_ERR_OUT_OF_DATA = 35; // Z
  SP_ERR_SCREENMODE_UNSUPPORTED = 36;
  SP_ERR_WINDOW_NOT_FOUND = 37;
  SP_ERR_INVALID_REGION = 38;
  SP_ERR_INVALID_GRAB_STRING = 39;
  SP_ERR_BANK_NOT_FOUND = 40;
  SP_ERR_ON_WITHOUT_DO = 41;
  SP_ERR_NO_RECOVER = 42;
  SP_ERR_INVALID_BANK = 43;
  SP_ERR_BANK_PROTECTED = 44;
  SP_ERR_INVALID_WAIT = 45;
  SP_ERR_INVALID_STREAM_ID = 46;
  SP_ERR_DIR_NOT_FOUND = 47;
  SP_ERR_LABEL_NOT_FOUND = 48;
  SP_ERR_DIV_BY_ZERO = 49;
  SP_ERR_NOT_PALETTE_FILE = 50;
  SP_ERR_UNBALANCED_STACK = 51;
  SP_ERR_LINE_NOT_FOUND = 52;
  SP_ERR_UNSUPPORTED_FORMAT = 53;
  SP_ERR_SOUND_ERROR = 54;
  SP_ERR_CHANNEL_LOST = 55;
  SP_ERR_RATE_OUT_OF_RANGE = 56;
  SP_ERR_UNSUPPORTED_BITS = 57;
  SP_ERR_VOLUME_OUT_OF_RANGE = 58;
  SP_ERR_PAN_OUT_OF_RANGE = 59;
  SP_ERR_MUSIC_LOST = 60;
  SP_ERR_INVALID_MUSIC_FILE = 61;
  SP_ERR_INVALID_PROCEDURE_NAME = 62;
  SP_ERR_ENDPROC_WITHOUT_PROC = 63;
  SP_ERR_PROC_NOT_CLOSED = 64;
  SP_ERR_PROC_NOT_FOUND = 65;
  SP_ERR_PROC_PARAM_COUNT = 66;
  SP_ERR_PARAMETER_ERROR = 67;
  SP_ERR_INVALID_FUNCTION_NAME = 68;
  SP_ERR_INVALID_FUNCTION_TYPE = 69;
  SP_ERR_FN_NOT_FOUND = 70;
  SP_ERR_ENDPROC_WITHOUT_PROC_CALL = 71;
  SP_ERR_EXITPROC_WITHOUT_PROC_CALL = 72;
  SP_ERR_DIRECTORYNOTFOUND = 73;
  SP_ERR_INVALID_SCALE = 74;
  SP_ERR_INVALID_FRAME = 75;
  SP_ERR_SPRITE_NOT_FOUND = 76;
  SP_ERR_NO_FRAMES = 77;
  SP_ERR_MISSING_DIRECTION = 78;
  SP_ERR_EMPTY_SPRITE = 79;
  SP_ERR_INVALID_IMAGE_FORMAT = 80;
  SP_ERR_UNSUPPORTED_IMAGE_FORMAT = 81;
  SP_ERR_INVALID_GRAPHIC_STRING = 82;
  SP_ERR_GRAPHIC_NOT_FOUND = 83;
  SP_ERR_INVALID_WINDOW = 84;
  SP_ERR_LINE_WITHOUT_STR = 85;
  SP_ERR_PACKAGE_CREATE_ERROR = 86;
  SP_ERR_INVALID_PACKAGE = 87;
  SP_ERR_INVALID_ASSIGNMENT = 88;
  SP_ERR_ASSIGNMENT_NOT_FOUND = 89;
  SP_ERR_DIR_NOT_EMPTY = 90;
  SP_ERR_WRITE_PROTECT = 91;
  SP_ERR_FILE_ALREADY_EXISTS = 92;
  SP_ERR_DIR_ALREADY_EXISTS = 93;
  SP_ERR_DIR_CREATE_FAILED = 94;
  SP_ERR_MISMATCHED_MASK = 95;
  SP_ERR_RENAME_FAILED = 96;
  SP_ERR_PACKAGE_RENAME_HOST = 97;
  SP_ERR_PACKAGE_NOT_OPEN = 98;
  SP_ERR_INVALID_DATA_FILE = 99;
  SP_ERR_GRAPHIC_UNSUITED = 100;
  SP_ERR_GRAPHIC_LOST = 101;
  SP_ERR_INVALID_SEPARATOR = 102;
  SP_ERR_INVALID_STRUCTURE_NAME = 103;
  SP_ERR_INVALID_STRUCT_MEMBER = 104;
  SP_ERR_STRUCT_NOT_FOUND = 105;
  SP_ERR_MISSING_STRUCT = 106;
  SP_ERR_STRUCT_NOT_REF = 107;
  SP_ERR_INPUT_WITHOUT_VAR = 108;
  SP_ERR_MIXED_IN_TERMS = 109;
  SP_ERR_INVALID_EACH_VAR = 110;
  SP_ERR_STATEMENT_OUT_OF_REACH = 111;
  SP_ERR_INVALID_ARGUMENT = 112;
  SP_ERR_OUT_OF_STACK = 113;
  SP_ERR_INVALID_SYSVAR = 114;
  SP_ERR_INVALID_SYSVAR_TYPE = 115;
  SP_ERR_INVALID_SYSVAR_SIZE = 116;
  SP_ERR_INSUFFICIENT_PARAMETERS = 117;
  SP_ERR_INVALID_HARDWARE = 118;
  SP_ERR_INVALID_NUB = 119;
  SP_ERR_INVALID_NUB_MODE = 120;
  SP_ERR_INVALID_ARRAY_VAR = 121;
  SP_ERR_UNSUITABLE_ARRAY = 122;
  SP_ERR_STATEMENT_LOST = 123;
  SP_ERR_INVALID_KEYBOARD = 124;
  SP_ERR_ORG_INVALID = 125;
  SP_ERR_CLONE_NOT_FOUND = 126;
  SP_ERR_OUT_OF_CLONES = 127;
  SP_ERR_INVALID_NOTE = 128;
  SP_ERR_FILE_NOT_FOUND = 129;
  SP_ERR_INVALID_FILENAME = 130;
  SP_ERR_COULD_NOT_OPEN_FILE = 131;
  SP_ERR_FILE_NOT_OPEN = 132;
  SP_ERR_FILE_LOCKED = 133;
  SP_ERR_INVALID_DURATION = 134;
  SP_ERR_CASE_WITHOUT_END_CASE = 135;
  SP_ERR_OUT_OF_CASE = 136;
  SP_ERR_MISMATCHED_WHEN = 137;
  SP_ERR_KEY_NOT_FOUND = 138;
  SP_ERR_KEY_ALREADY_EXISTS = 139;
  SP_ERR_INVALID_MATRIX = 140;
  SP_ERR_MATRIX_SINGULAR = 141;
  SP_ERR_MISMATCHED_MATRICES = 142;
  SP_ERR_OUT_OF_MEMORY = 143;
  SP_ERR_CONST_IN_ASSIGNMENT = 144;
  SP_ERR_ZONE_NOT_FOUND = 145;
  SP_ERR_REGEXP_ERROR = 146;
  SP_ERR_INVALID_INTEGER = 147;
  SP_ERR_INVALID_RADIX = 148;
  SP_ERR_EMPTY_SPLIT_STRING = 149;
  SP_ERR_ASM_ERROR = 150;
  SP_ERR_INVALID_DEPTH = 151;
  SP_ERR_UNHANDLED = 152;
  SP_ERR_MENU_NOT_FOUND = 153;
  SP_ERR_INVALID_MENU_ITEM = 154;
  SP_ERR_INVALID_SUBMENU = 155;
  SP_ERR_EDITOR = 156;
  SP_ERR_INSTALL_DONE = 157;
  SP_ERR_INVALID_WINDOW_EX = 158;
  SP_ERR_BREAKPOINT = 159;

  MAXERROR = 159;

  // Runtime error codes.

  SP_ERR_BANK_ID_NOT_FOUND = -1;
  SP_ERR_CHAR_OUT_OF_RANGE = -2;
  SP_ERR_BANK_INVALID_FORMAT = -3;
  SP_ERR_BAD_CHARACTER_SIZE = -4;
  SP_ERR_PRINT_ABANDONED = -11;
  SP_ERR_STREAM_ID_NOT_FOUND = -12;

  ErrorMessages: Array[0..MAXERROR] of aString =
    ('Ok',
     'Missing numeric expression',
     'Missing bracket',
     'Missing operator',
     'Illegal character in expression',
     'Unhandled function',
     'Missing String expression',
     'Invalid keyword',
     'Missing separator',
     'Variable not found',
     'Missing "=" character',
     'Integer out of range',
     'Invalid String-slicer',
     'Subscript wrong',
     'Array not found',
     'Invalid numeric argument',
     'BREAK into program',
     'Expecting TO or SUB',
     'RETURN without GO SUB',
     'STOP statement',
     'Missing variable',
     'Missing TO',
     'STEP expected',
     'NEXT without FOR',
     'Invalid colour item',
     'IF without THEN',
     'Types not compatible',
     'Nonsense in BASIC',
     'File in use',
     'Unable to save',
     'File not found',
     'LOAD failed',
     'LOOP without DO',
     'WHILE without LOOP',
     'EXIT without LOOP',
     'Out of DATA',
     'Screen mode unsupported',
     'Window not found',
     'Invalid region',
     'Invalid Graphic String',
     'Bank not found',
     'ON without DO',
     'Recovery unavailable',
     'Invalid bank type',
     'Bank protected',
     'Invalid WAIT period',
     'Invalid stream ID',
     'Directory not found',
     'Label not declared',
     'Divide by zero',
     'File not valid palette',
     'Stack unbalanced in ',
     'Line not found',
     'Unsupported sound file',
     'Sound error',
     'Channel lost',
     'Sample rate out of range',
     'Unsupported sample bit depth',
     'Volume out of range',
     'Panning out of range',
     'Music lost',
     'Invalid music file',
     'Invalid procedure name',
     'END PROC without DEF PROC',
     'Procedure has no END PROC',
     'PROC without DEF PROC',
     'Invalid parameter count',
     'Parameter error',
     'Invalid function name',
     'Mismatched function type',
     'FN without DEF FN',
     'END PROC without PROC or CALL',
     'EXIT PROC without PROC or CALL',
     'Directory not found',
     'Invalid SCALE factor',
     'Invalid sprite frame',
     'Sprite not found',
     'No frames in sprite',
     'Missing CW or CCW direction',
     'Empty sprite',
     'Invalid image format',
     'Unsupported image type',
     'Invalid graphic string value',
     'Graphic not found',
     'Invalid window for SPRITE',
     'READ LINE without string variable',
     'Error creating package',
     'Invalid package',
     'Invalid assignment',
     'Assignment not found',
     'Directory not empty',
     'Write protect error',
     'File already exists in COPY',
     'Directory already exists',
     'Could not create directory',
     'Mismatched mask in RENAME',
     'Could not RENAME file',
     'Cannot RENAME out of package',
     'Package not open',
     'Invalid DATA file',
     'GRAPHIC not suitable for tile size',
     'TILEMAP graphics lost',
     'Invalid separator',
     'Invalid structure name',
     'Invalid structure member',
     'STRUCT not found',
     'No STRUCT for string variable',
     'STRUCT member cannot be referenced',
     'INPUT without variable',
     'Mixed terms for IN',
     'Invalid variable for EACH',
     'Statement out of reach',
     'Invalid argument',
     'Out of stack',
     'Invalid system variable',
     'System variable type mismatch',
     'System variable data size out of range',
     'Not enough parameters',
     'Invalid hardware type',
     'Invalid nub ID',
     'Invalid nub mode',
     'Invalid array variable',
     'Unsuitable array',
     'Statement lost',
     'Invalid keyboard definition',
     'Invalid ORIGIN',
     'Clone not found',
     'Out of clones',
     'Invalid note name',
     'File not found',
     'Invalid file name',
     'Could not open file',
     'File not open',
     'File locked for writing',
     'Invalid duration',
     'CASE without END CASE',
     'Out of CASE',
     'Mismatched type in WHEN',
     'Key not found in array',
     'Key already exists in array',
     'Invalid matrix',
     'Cannot invert singular matrix',
     'Mismatched matrix sizes',
     'Out of memory',
     'CONST in assignment',
     'Zone not found',
     'Bad regular expression',
     'Invalid integer in DECIMAL',
     'Invalid radix in DECIMAL',
     'Empty string for SPLIT',
     'Syntax error in assembler',
     'Invalid colour depth',
     'Handler not found',
     'Menu not found',
     'Invalid menu item',
     'Invalid submenu',
     'Editor error',
     'Installation finished',
     'Invalid window',
     'Breakpoint reached');

implementation

end.
