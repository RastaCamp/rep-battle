@echo off
cd /d "%~dp0"
start "Rep Battle" cmd /k "cd /d "%~dp0" && C:\flutter\bin\flutter.bat pub get && C:\flutter\bin\flutter.bat run -d chrome"
