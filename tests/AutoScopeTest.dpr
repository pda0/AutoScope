{**********************************************************************
    ● Copyright(c) 2017 Dmitriy Pomerantsev <pda2@yandex.ru>

    See the file COPYING.FPC, included in this distribution,
    for details about the copyright.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

 **********************************************************************}
program AutoScopeTest;
{$IFDEF FPC}
  {$CODEPAGE UTF8}
  {$MODE DELPHI}{$H+}
  {$IFDEF WINDOWS}{$DEFINE USE_APPTYPE}{$ENDIF}
  {$IFDEF MACOS}{$DEFINE USE_APPTYPE}{$ENDIF}
  {$IFDEF OS2}{$DEFINE USE_APPTYPE}{$ENDIF}
  {$IFDEF AMIGA}{$DEFINE USE_APPTYPE}{$ENDIF}
{$ELSE}
  {$IFDEF VER180}{$DEFINE OLD_DELPHI}{$ENDIF}
  {$IFDEF VER185}{$DEFINE OLD_DELPHI}{$ENDIF}
  {$IFDEF VER190}{$DEFINE OLD_DELPHI}{$ENDIF}
  {$DEFINE USE_APPTYPE}
{$ENDIF}

{$IFDEF CONSOLE_TESTRUNNER}
  {$IFDEF USE_APPTYPE}{$APPTYPE CONSOLE}{$ENDIF}
{$ENDIF}

uses
  {$IFDEF FPC}
    {$IFDEF UNIX}
    cwstring,
    {$ENDIF}
    {$IFDEF CONSOLE_TESTRUNNER}
    Classes,
    ConsoleTestRunner,
    {$ELSE}
    Interfaces,
    Forms,
    GuiTestRunner,
    {$ENDIF}
  {$ELSE}
    {$IFDEF OLD_DELPHI}
    Forms,
    TestFramework,
    GUITestRunner,
    TextTestRunner,
    {$ELSE}
    DUnitTestRunner,
    {$ENDIF}
  {$ENDIF}
  AutoScope in '..\AutoScope.pas',
  TestScoped in 'TestScoped.pas';

{$R *.res}

{$IFDEF CONSOLE_TESTRUNNER}
var
  Application: TTestRunner;
{$ENDIF}

begin
  {$IFDEF FPC}
    {$IFDEF CONSOLE_TESTRUNNER}
    Application := TTestRunner.Create(nil);
    {$ENDIF}
    Application.Initialize;
    Application.Run;
    {$IFDEF CONSOLE_TESTRUNNER}
    Application.Free;
    {$ENDIF}
  {$ELSE}
    ReportMemoryLeaksOnShutdown := True;
    {$IFDEF OLD_DELPHI}
    Application.Initialize;
    if IsConsole then
      TextTestRunner.RunRegisteredTests
    else
      GUITestRunner.RunRegisteredTests;
    {$ELSE}
    DUnitTestRunner.RunRegisteredTests;
    {$ENDIF}
  {$ENDIF}
end.

