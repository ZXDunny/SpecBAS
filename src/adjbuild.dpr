program adjbuild;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  Classes;

var
  s: String;
  sl: TStringlist;
  i, p, OldVer: Integer;

begin
  try
    { TODO -oUser -cConsole Main : Insert code here }
    sl := TStringlist.Create;
    sl.LoadFromFile('SpecBAS.rc');

    s := sl[1];
    i := length(s);
    while s[i] in ['0'..'9'] do
      Dec(i);
    OldVer := StrToInt(Copy(s, i +1));

    For i := 0 To sl.Count -1 do begin
      p := Pos(IntToStr(Oldver), sl[i]);
      if p > 0 then
        sl[i] := Copy(sl[i], 1, p -1) + IntToStr(Oldver +1) + Copy(sl[i], p + Length(IntToStr(Oldver)));
    end;
    sl.SaveToFile('SpecBAS.rc');
    sl.Free;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
