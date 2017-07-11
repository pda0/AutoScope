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
    FExObject: TObject;
    FExCreated, FExDeleted: Integer;
    class function GetMemoryUsed: NativeUInt; static;
    procedure MakeException;
    procedure MakeConstructorException;
    procedure MakeDestructorException;
    procedure SolveHanoi;
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
    procedure TestConstructorException;
    procedure TestDestructorException;
    procedure TestHanoi;
  end;

implementation

uses
  Classes, SysUtils;

const
  MAX_DISCS = 5;

type
  TTestObject = class
  protected
    FCreated, FDeleted: PInteger;
  public
    constructor Create(CreatedPtr, DeletedPtr: PInteger); virtual;
    destructor Destroy; override;
    procedure Dummy;
  end;

  TTestCFailObject = class(TTestObject)
  public
    constructor Create(CreatedPtr, DeletedPtr: PInteger); override;
  end;

  TTestDFailObject = class(TTestObject)
  private
    FFail: Boolean;
  public
    constructor Create(CreatedPtr, DeletedPtr: PInteger); override;
    destructor Destroy; override;
    property Fail: Boolean read FFail write FFail;
  end;

  IRenderer = Interface
    procedure RenderLine(AnStr: string);
  end;

  TPegs = (FirstPeg, SecondPeg, ThirdPeg);

  TPeg = record
    Discs: array [0 .. MAX_DISCS - 1] of Integer;
    Count: Integer;
    procedure MoveTopDisc(var DestPeg: TPeg);
    function RenderLine(Line: Integer): string;
  end;

  TTowers = record
    Pegs: array [TPegs] of TPeg;
    procedure Init;
    procedure Render(Rendered: IRenderer);
  end;

  TRenderer = class(TInterfacedObject, IRenderer)
  private
    FStrings: TStrings;
  public
    constructor Create(const Strings: TStrings);
    procedure RenderLine(AnStr: string);
  end;

{ TTestObject }

constructor TTestObject.Create(CreatedPtr, DeletedPtr: PInteger);
begin
  inherited Create;
  FCreated := CreatedPtr;
  FDeleted := DeletedPtr;
  Inc(FCreated^);
end;

destructor TTestObject.Destroy;
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

{ TTestCFailObject }

constructor TTestCFailObject.Create(CreatedPtr, DeletedPtr: PInteger);
begin
  Abort;
  inherited;
end;

{ TTestDFailObject }

constructor TTestDFailObject.Create(CreatedPtr, DeletedPtr: PInteger);
begin
  inherited;
  FFail := True;
end;

destructor TTestDFailObject.Destroy;
begin
  if FFail then
    Abort;

  inherited;
end;

{ TPeg }

procedure TPeg.MoveTopDisc(var DestPeg: TPeg);
begin
  Dec(Count);
  DestPeg.Discs[DestPeg.Count] := Discs[Count];
  Discs[Count] := 0;
  Inc(DestPeg.Count);
end;

function TPeg.RenderLine(Line: Integer): string;
var
  TowerWidth, RingWidth, Spaces: Integer;
begin
  TowerWidth := 3 + 2 * (MAX_DISCS - 1);

  if Line >= MAX_DISCS then
    RingWidth := 1
  else
    RingWidth := 1 + 2 * Discs[Line];

  Spaces := (TowerWidth - RingWidth) div 2;

  if RingWidth = 1 then
    Result := '#'
  else
    Result := StringOfChar('@', RingWidth);

  Result := StringOfChar(' ', Spaces) + Result + StringOfChar(' ', Spaces);
end;

{ TTowers }
procedure TTowers.Init;
var
  i: Integer;
begin
  Pegs[FirstPeg].Count  := MAX_DISCS;
  Pegs[SecondPeg].Count := 0;
  Pegs[ThirdPeg].Count  := 0;
  for i := 0 to MAX_DISCS - 1 do
  begin
    Pegs[FirstPeg].Discs[i]  := MAX_DISCS - i;
    Pegs[SecondPeg].Discs[i] := 0;
    Pegs[ThirdPeg].Discs[i]  := 0;
  end;
end;

{ TRenderer }

constructor TRenderer.Create(const Strings: TStrings);
begin
  FStrings := Strings;
end;

procedure TRenderer.RenderLine(AnStr: string);
begin
  FStrings.Append(AnStr);
end;

procedure TTowers.Render(Rendered: IRenderer);
var
  PegLine: string;
  Line: Integer;
  Peg: TPegs;
begin
  Rendered.RenderLine('');
  for Line := MAX_DISCS downto 0 do
  begin
    PegLine := '';
    for Peg := Low(Pegs) to High(Pegs) do
      PegLine := PegLine + Pegs[Peg].RenderLine(Line);
    Rendered.RenderLine(PegLine);
  end;
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
  T2 := nil;

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
  P2 := nil;
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

procedure TTestScoped.MakeConstructorException;
var
  Scoped: TScoped;
  T1, T2: TTestObject;
begin
  T1 := Scoped[TTestObject.Create(@FExCreated, @FExDeleted)] as TTestObject;
  T2 := Scoped[TTestCFailObject.Create(@FExCreated, @FExDeleted)] as TTestObject;

  T1.Dummy;
  T2.Dummy;
end;

procedure TTestScoped.TestConstructorException;
begin
  FExCreated := 0;
  FExDeleted := 0;

  CheckException(MakeConstructorException, EAbort);

  CheckEquals(1, FExCreated);
  CheckEquals(1, FExDeleted);
end;

procedure TTestScoped.MakeDestructorException;
var
  Scoped: TScoped;
  T1, T2, T3: TTestObject;
begin
  T1 := Scoped[TTestObject.Create(@FExCreated, @FExDeleted)] as TTestObject;
  T2 := Scoped[TTestDFailObject.Create(@FExCreated, @FExDeleted)] as TTestObject;
  T3 := Scoped[TTestObject.Create(@FExCreated, @FExDeleted)] as TTestObject;

  FExObject := T2;

  T1.Dummy;
  T2.Dummy;
  T3.Dummy;
end;

procedure TTestScoped.TestDestructorException;
begin
  FExCreated := 0;
  FExDeleted := 0;

  CheckException(MakeDestructorException, EAbort);

  CheckEquals(3, FExCreated);
  CheckEquals(2, FExDeleted);

  (FExObject as TTestDFailObject).Fail := False;
  FExObject.Free;

  CheckEquals(3, FExDeleted);
end;

{ The solution to the `Tower of Hanoi' puzzle is used to get a large enough and
  complex code to make sure that the compiler does not remove Scoped ahead of
  time. }
procedure TTestScoped.SolveHanoi;
var
  Scoped: TScoped;
  Towers: TTowers;
  Solution: TStrings;
  Renderer: IRenderer;
  T: TTestObject;

  procedure MoveStack(Amount: Integer; SrcPeg, DestPeg: TPegs);
  var
    Scoped: TScoped;
    Renderer: IRenderer;
    T2: TTestObject;
    FreePeg: TPegs;
    CreatedCounter, DeletedCounter: Integer;
  begin
    FreePeg := FirstPeg;
    CreatedCounter := 0;
    DeletedCounter := 0;
    T2 := Scoped[TTestObject.Create(@CreatedCounter, @DeletedCounter)] as TTestObject;
    T2.Dummy;

    if Amount > 0 then
    begin
      Renderer := TRenderer.Create(Solution);
      Dec(Amount);

      case SrcPeg of
        FirstPeg:
          if DestPeg = SecondPeg then
            FreePeg := ThirdPeg
          else
            FreePeg := SecondPeg;
        SecondPeg:
          if DestPeg = ThirdPeg then
            FreePeg := FirstPeg
          else
            FreePeg := ThirdPeg;
        ThirdPeg:
          if DestPeg = FirstPeg then
            FreePeg := SecondPeg
          else
            FreePeg := FirstPeg;
      end;

      MoveStack(Amount, SrcPeg, FreePeg);
      Towers.Pegs[SrcPeg].MoveTopDisc(Towers.Pegs[DestPeg]);
      Towers.Render(Renderer);
      MoveStack(Amount, FreePeg, DestPeg);
    end;

    CheckEquals(1, CreatedCounter);
    CheckEquals(0, DeletedCounter);
  end;
begin
  T := Scoped[TTestObject.Create(@FExCreated, @FExDeleted)] as TTestObject;
  Solution := Scoped[TStringList.Create] as TStringList;
  T.Dummy;

  Renderer := TRenderer.Create(Solution);
  Towers.Init;
  Towers.Render(Renderer);
  MoveStack(MAX_DISCS, FirstPeg, SecondPeg);
  CheckEquals(0, FExDeleted);
end;

procedure TTestScoped.TestHanoi;
begin
  FExCreated := 0;
  FExDeleted := 0;

  SolveHanoi;

  CheckEquals(1, FExCreated);
  CheckEquals(1, FExDeleted);
end;

initialization
  RegisterTest('AutoScope', TTestScoped.Suite);

end.
