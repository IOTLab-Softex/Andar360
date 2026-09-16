@echo off
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0bin\andar360.ps1" %*
if errorlevel 1 pause
