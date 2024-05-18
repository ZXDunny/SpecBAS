// Copyright (C) 2024 By Paul Dunn
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

unit SP_Util2;

interface

Uses Math, SP_Util;

Function  SP_Power(Base, Exponent: aFloat): aFloat; inline;

implementation

Function SP_Power(Base, Exponent: aFloat): aFloat; inline;
Begin

  If Base >= 0 Then
    Result := Power(Base, Exponent)
  Else
    Result := -Power(Abs(Base), Exponent);

End;

end.
