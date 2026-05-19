@echo off
REM Rep Battle launcher - logs to launch_log.txt if window closes too fast
set "LOG=%~dp0launch_log.txt"
echo [%date% %time%] Starting > "%LOG%"

cd /d "%~dp0" 2>>"%LOG%"
if errorlevel 1 (
  echo CD failed to %~dp0 >> "%LOG%"
  goto :fail
)
echo CD ok: %CD% >> "%LOG%"

set "FLUTTER=C:\flutter\bin\flutter.bat"
if not exist "%FLUTTER%" set "FLUTTER=%LOCALAPPDATA%\flutter\bin\flutter.bat"
if not exist "%FLUTTER%" set "FLUTTER=flutter"

echo Flutter: %FLUTTER% >> "%LOG%"
where flutter >> "%LOG%" 2>&1

title Rep Battle
echo ============================================
echo   REP BATTLE
echo ============================================
echo.
echo Project: %CD%
echo Flutter: %FLUTTER%
echo.

echo [1/2] pub get...
call "%FLUTTER%" pub get >> "%LOG%" 2>&1
if errorlevel 1 goto :fail

echo [2/2] Starting Chrome...
echo Log file: %LOG%
echo.
call "%FLUTTER%" run -d chrome
set ERR=%ERRORLEVEL%

echo. >> "%LOG%"
echo Exit code: %ERR% >> "%LOG%"
echo.
if not "%ERR%"=="0" echo Run failed. See %LOG%
pause
exit /b %ERR%

:fail
echo. >> "%LOG%"
echo FAILED - see launch_log.txt in project folder >> "%LOG%"
echo.
echo Something went wrong. Open launch_log.txt for details.
pause
exit /b 1
