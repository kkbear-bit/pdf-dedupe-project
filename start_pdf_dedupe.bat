@echo off
setlocal
pushd "%~dp0"
powershell.exe -STA -NoProfile -ExecutionPolicy Bypass -File ".\pdf-dedupe-launcher.ps1"
echo.
pause
popd

