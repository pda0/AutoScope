# AutoScope
Have you tired of infinite `try`/`finally` of proper class handling like:
```delphi
SomeObject1 := TSomeObject1.Create;
try
  SomeObject2 := TSomeObject2.Create;
  try
    SomeObject3 := TSomeObject3.Create;
    try
      <...>
    finally
      SomeObject3.Free;
    end;
  finally
    SomeObject2.Free;
  end;
finally
  SomeObject1.Free;
end;
```

or slightly more smart but still annoying:
```delphi
  SomeObject1 := nil;
  SomeObject2 := nil;
  SomeObject3 := nil;
  try
    SomeObject1 := TSomeObject1.Create;
    SomeObject2 := TSomeObject2.Create;
    SomeObject3 := TSomeObject3.Create;
    <...>
  finally
    SomeObject3.Free;
    SomeObject2.Free;
    SomeObject1.Free;
  end;
```

Then try AutoScope. With it you can write like this:
```delphi
uses
  AutoScope,<...>;
<...>
procedure SomeProc;
var
  Scoped: TScoped;
  <...>
begin
  SomeObject1 := Scoped[TSomeObject1.Create] as TSomeObject1;
  SomeObject2 := Scoped[TSomeObject2.Create] as TSomeObject2;
  SomeObject3 := Scoped[TSomeObject3.Create] as TSomeObject3;
  <...>
end;
```

That's it! At the `end` an implicit call of `Scoped.Finalize` happens and all of stored objects will freed in reverse order. AutoScope also can handle with raw memory block, allocated by `GetMem`/`FreeMem` functions. (But not with typed `New`/`Dispose` pointers.)

Compatible with Delphi 2007+ (may be with 2006+) and Free Pascal 2.6.0+.
