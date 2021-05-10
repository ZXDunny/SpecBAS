unit SP_SliderUnit;

interface

Uses SP_BaseComponentUnit, SP_Util;

Type

SP_Slider = Class(SP_BaseComponent)

  Private


  Public

    Procedure Draw; Override;
    Constructor Create(Owner: SP_BaseComponent);
    Destructor  Destroy; Override;

End;
pSP_Slider = ^SP_Slider;

implementation

Constructor SP_Slider.Create(Owner: SP_BaseComponent);
Begin
//
End;

Destructor SP_Slider.Destroy;
Begin
//
End;

Procedure SP_Slider.Draw;
Begin
//
End;


end.
