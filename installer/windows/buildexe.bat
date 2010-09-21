::@echo off
:: job to build .EXE
:: assumes that
::   http://svn.opengeo.org/suite/trunk/installer
:: has been checked out
:: Also assumes that it is running inside installer\windows

:: Start by cleaning up target
rd /s /q ..\..\target\ >nul 2>nul

::Auto defined variables (for when not building through Hudson)
if x%repo_path%==x (
  set repo_path=trunk
)
if x%revision%==x (
  set revision=latest
)



:: Get REPO_PATH and convert slashes to dashes


for /f "tokens=1,2 delims=\/" %%a in ("%repo_path%") do (
  if not x%%b==x (
    set repo-path=%%a-%%b
  ) else (
    set repo-path=%%a
  )
)

:: generate id string
if %revision%==latest (
  set id=latest
) else (
  set id=%repo-path%-%revision%
)

set mainzip=opengeosuite-%id%-win.zip
set dashzip=dashboard-%id%-win32.zip

:: Get the maven artifact in place
@echo Downloading http://suite.opengeo.org/builds/%mainzip% ...
wget http://suite.opengeo.org/builds/%mainzip% >nul 2>nul
mkdir ..\..\target\win 2>nul
unzip %mainzip% -d ..\..\target\win
del %mainzip%

:: Get the dashboard in place
@echo Downloading http://suite.opengeo.org/builds/%dashzip% ...
wget http://suite.opengeo.org/builds/%dashzip% >nul 2>nul
rd /s /q ..\..\target\win\dashboard
unzip %dashzip% -d ..\..\target\win\
del %dashzip%
ren "..\..\target\win\OpenGeo Dashboard" dashboard

:: Get today's date
for /F "tokens=1* delims= " %%A in ('DATE/T') do set CDATE=%%B
for /F "tokens=1,2 eol=/ delims=/ " %%A in ('DATE/T') do set mm=%%B
for /F "tokens=1,2 delims=/ eol=/" %%A in ('echo %CDATE%') do set dd=%%B
for /F "tokens=2,3 delims=/ " %%A in ('echo %CDATE%') do set yyyy=%%B
set todaysdate=%yyyy%-%mm%-%dd%

:: Get version number
findstr suite_version ..\..\target\win\version.ini > "%TEMP%\vertemp.txt"
set /p vertemp=<"%TEMP%\vertemp.txt"
del "%TEMP%\vertemp.txt"
for /f "tokens=1,2 delims=/=" %%a in ("%vertemp%") do set trash=%%a&set version=%%b

:: Get revision number
:: Note that this must be numeric, so is different from what is passed from Hudson
findstr svn_revision ..\..\target\win\version.ini > "%TEMP%\revtemp.txt"
set /p revtemp=<"%TEMP%\revtemp.txt"
del "%TEMP%\revtemp.txt"
for /f "tokens=1,2 delims=/=" %%a in ("%revtemp%") do set trash=%%a&set rev=%%b

:: Figure out if the version is a snapshot
for /f "tokens=1,2,3 delims=." %%a in ("%version%") do set vermajor=%%a&set verminor=%%b&set verpatch=%%c
if "%vermajor%"=="" goto Snapshot
if "%verminor%"=="" goto Snapshot
if "%verpatch%"=="" goto Snapshot
set longversion=%version%.%rev%
goto Build
:Snapshot
set longversion=0.0.0.%rev%
goto Build

:Build
:: Now build the EXE
@echo Running NSIS (version %version%, longversion %longversion%) ...
makensis /DVERSION=%version% /DLONGVERSION=%longversion% OpenGeoInstaller.nsi

:: Clean up
rd /s /q ..\..\target\