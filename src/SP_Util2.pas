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
