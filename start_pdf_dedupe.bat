@echo off
setlocal
pushd "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\pdf-dedupe-launcher.ps1"
echo.
pause
popd
