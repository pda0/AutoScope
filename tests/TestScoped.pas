{**********************************************************************
    ● Copyright(c) 2017 Dmitriy Pomerantsev <pda2@yandex.ru>

    See the file COPYING.FPC, included in this distribution,
    for details about the copyright.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

 **********************************************************************}
unit TestScoped;
{$IFDEF FPC}
  {$CODEPAGE UTF8}
  {$MODE DELPHI}{$H+}
{$ENDIF}

interface

uses
  {$IFDEF FPC}
  fpcunit, testregistry,
  {$ELSE}
  TestFramework,
  {$ENDIF}
  AutoScope;

type
  TTestScoped = class(TTestCase)
  private
    FExCreated, FExDeleted: Integer;
    class function GetMemoryUsed: NativeUInt; static;
    procedure MakeException;
  published
    procedure TestEmpty;
    procedure TestAddObject;
    procedure TestProperty;
    procedure TestAddMem;
    procedure TestGetMem;
    procedure TestFreeMem;
    procedure TestReallocMem;
    procedure TestMixed;
    procedure TestRemoveObject;
    procedure TestRemoveMem;
    procedure TestException;
  end;

implementation

uses
  SysUtils;

type
  TTestObject = class
  private
    FCreated, FDeleted: PInteger;
  public
    constructor Create(CreatedPtr, DeletedPtr: PInteger);
    procedure BeforeDestruction; override;
    procedure Dummy;
  end;

constructor TTestObject.Create(CreatedPtr, DeletedPtr: PInteger);
begin
  inherited Create;
  FCreated := CreatedPtr;
  FDeleted := DeletedPtr;
  Inc(FCreated^);
end;

procedure TTestObject.BeforeDestruction;
begin
  if Assigned(FDeleted) then
  begin
    Inc(FDeleted^);
    FDeleted := nil;
  end;
  inherited;
end;

procedure TTestObject.Dummy;
begin
end;

{ TTestScoped }

class function TTestScoped.GetMemoryUsed: NativeUInt;
{$IFNDEF FPC}
var
  st: TMemoryManagerState;
  i: Integer;
{$ENDIF}
begin
  {$IFDEF FPC}
  Result := NativeUint(GetHeapStatus.TotalAllocated);
  {$ELSE}
  GetMemoryManagerState(st);
  Result := st.TotalAllocatedMediumBlockSize + st.TotalAllocatedLargeBlockSize;
  for i := Low(st.SmallBlockTypeStates) to High(st.SmallBlockTypeStates) do
    Result := Result + st.SmallBlockTypeStates[i].UseableBlockSize *
      st.SmallBlockTypeStates[i].AllocatedBlockCount;
  {$ENDIF}
end;

{$IFDEF FPC}{$PUSH}{$NOTES OFF}{$ENDIF}{$HINTS OFF}
procedure TTestScoped.TestEmpty;
var
  Mem1, Mem2: NativeUInt;

  procedure ScopedTest;
  var
    Scoped: TScoped;
  begin
    { Here we have two implicit calls:
      @InitializeRecord(Scoped);
      @FinalizeRecord(Scoped); }
  end;
begin
  Mem1 := GetMemoryUsed;
  ScopedTest;
  Mem2 := GetMemoryUsed;

  CheckEquals(Mem1, Mem2);
end;
{$IFDEF FPC}{$POP}{$ELSE}{$HINTS ON}{$ENDIF}

procedure TTestScoped.TestAddObject;
var
  CreatedCounter, DeletedCounter: Integer;

  procedure ScopedTest;
  var
    Scoped: TScoped;
    T1, T2, T3: TTestObject;
  begin
    T1 := Scoped.AddObject(TTestObject.Create(@CreatedCounter, @DeletedCounter)) as TTestObject;
    T2 := Scoped.AddObject(TTestObject.Create(@CreatedCounter, @DeletedCounter)) as TTestObject;
    T3 := Scoped.AddObject(TTestObject.Create(@CreatedCounter, @DeletedCounter)) as TTestObject;
    T1.Dummy;
    T2.Dummy;
    T3.Dummy;
  end;
begin
  CreatedCounter := 0;
  DeletedCounter := 0;

  ScopedTest;
  CheckEquals(3, CreatedCounter);
  CheckEquals(3, DeletedCounter);
end;

procedure TTestScoped.TestProperty;
var
  CreatedCounter, DeletedCounter: Integer;

  procedure ScopedTest;
  var
    Scoped: TScoped;
    T1, T2, T3: TTestObject;
  begin
    T1 := Scoped[TTestObject.Create(@CreatedCounter, @DeletedCounter)] as TTestObject;
    T2 := Scoped[TTestObject.Create(@CreatedCounter, @DeletedCounter)] as TTestObject;
    T3 := Scoped[TTestObject.Create(@CreatedCounter, @DeletedCounter)] as TTestObject;
    T1.Dummy;
    T2.Dummy;
    T3.Dummy;
  end;
begin
  CreatedCounter := 0;
  DeletedCounter := 0;

  ScopedTest;
  CheckEquals(3, CreatedCounter);
  CheckEquals(3, DeletedCounter);
end;

procedure TTestScoped.TestAddMem;
var
  Mem1, Mem2: NativeUInt;

  procedure ScopedTest;
  var
    Scoped: TScoped;
    P: Pointer;
  begin
    GetMem(P, 64);
    Scoped.AddMem(P);
  end;
begin
  Mem1 := GetMemoryUsed;
  ScopedTest;
  Mem2 := GetMemoryUsed;

  CheckEquals(Mem1, Mem2);
end;

procedure TTestScoped.TestGetMem;
var
  Mem1, Mem2: NativeUInt;

  procedure ScopedTest;
  var
    Scoped: TScoped;
    P1, P2, P3: Pointer;
  begin
    Scoped.GetMem(P1, 64);
    Scoped.GetMem(P2, 128);
    Scoped.GetMem(P3, 64);
  end;
begin
  Mem1 := GetMemoryUsed;
  ScopedTest;
  Mem2 := GetMemoryUsed;

  CheckEquals(Mem1, Mem2);
end;

procedure TTestScoped.TestFreeMem;
var
  Mem1, Mem2: NativeUInt;

  procedure ScopedTest;
  var
    Scoped: TScoped;
    P1, P2, P3: Pointer;
  begin
    Scoped.GetMem(P1, 64);
    Scoped.GetMem(P2, 128);
    Scoped.GetMem(P3, 64);
    Scoped.FreeMem(P2);
  end;
begin
  Mem1 := GetMemoryUsed;
  ScopedTest;
  Mem2 := GetMemoryUsed;

  CheckEquals(Mem1, Mem2);
end;

procedure TTestScoped.TestReallocMem;
var
  Mem1, Mem2: NativeUInt;

  procedure ScopedTest;
  var
    Scoped: TScoped;
    P: Pointer;
  begin
    Scoped.GetMem(P, 64);
    Scoped.ReallocMem(P, 128);
  end;
begin
  Mem1 := GetMemoryUsed;
  ScopedTest;
  Mem2 := GetMemoryUsed;

  CheckEquals(Mem1, Mem2);
end;

procedure TTestScoped.TestMixed;
var
  Mem1, Mem2: NativeUInt;
  CreatedCounter, DeletedCounter: Integer;

  procedure ScopedTest;
  var
    Scoped: TScoped;
    T1, T2: TTestObject;
    P1, P2: Pointer;
  begin
    T1 := Scoped[TTestObject.Create(@CreatedCounter, @DeletedCounter)] as TTestObject;
    Scoped.GetMem(P1, 64);
    T2 := Scoped[TTestObject.Create(@CreatedCounter, @DeletedCounter)] as TTestObject;
    Scoped.GetMem(P2, 64);
    T1.Dummy;
    T2.Dummy;
  end;
begin
  CreatedCounter := 0;
  DeletedCounter := 0;

  Mem1 := GetMemoryUsed;
  ScopedTest;
  Mem2 := GetMemoryUsed;

  CheckEquals(2, CreatedCounter);
  CheckEquals(2, DeletedCounter);
  CheckEquals(Mem1, Mem2);
end;

procedure TTestScoped.TestRemoveObject;
var
  CreatedCounter, DeletedCounter: Integer;
  T1, T2, T3: TTestObject;

  procedure ScopedTest;
  var
    Scoped: TScoped;
  begin
    T1 := Scoped[TTestObject.Create(@CreatedCounter, @DeletedCounter)] as TTestObject;
    T2 := Scoped[TTestObject.Create(@CreatedCounter, @DeletedCounter)] as TTestObject;
    T3 := Scoped[TTestObject.Create(@CreatedCounter, @DeletedCounter)] as TTestObject;
    T1.Dummy;
    T2.Dummy;
    T3.Dummy;
    Scoped.RemoveObject(T2);
  end;
begin
  CreatedCounter := 0;
  DeletedCounter := 0;

  ScopedTest;
  CheckEquals(3, CreatedCounter);
  CheckEquals(2, DeletedCounter);

  T2.Free;
  CheckEquals(3, CreatedCounter);
  CheckEquals(3, DeletedCounter);
end;

procedure TTestScoped.TestRemoveMem;
var
  Mem1, Mem2: NativeUInt;
  P1, P2, P3: Pointer;

  procedure ScopedTest;
  var
    Scoped: TScoped;
  begin
    Scoped.GetMem(P1, 64);
    Scoped.GetMem(P2, 128);
    Scoped.GetMem(P3, 64);
    Scoped.RemoveMem(P2);
  end;
begin
  Mem1 := GetMemoryUsed;
  ScopedTest;
  Mem2 := GetMemoryUsed;

  CheckNotEquals(Mem1, Mem2);

  FreeMem(P2);
  Mem2 := GetMemoryUsed;

  CheckEquals(Mem1, Mem2);
end;

procedure TTestScoped.MakeException;
var
  Scoped: TScoped;
  T1, T2, T3: TTestObject;
begin
  T1 := Scoped[TTestObject.Create(@FExCreated, @FExDeleted)] as TTestObject;
  T2 := Scoped[TTestObject.Create(@FExCreated, @FExDeleted)] as TTestObject;
  T3 := Scoped[TTestObject.Create(@FExCreated, @FExDeleted)] as TTestObject;

  Abort;

  T1.Dummy;
  T2.Dummy;
  T3.Dummy;
end;

procedure TTestScoped.TestException;
begin
  FExCreated := 0;
  FExDeleted := 0;

  CheckException(MakeException, EAbort);

  CheckEquals(3, FExCreated);
  CheckEquals(3, FExDeleted);
end;

initialization
  RegisterTest('AutoScope', TTestScoped.Suite);

end.
