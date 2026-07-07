@echo off
cd /d "%~dp0"
echo.
echo   Sending current status to Telegram...
echo.
for %%f in (*.ps1) do powershell -NoProfile -File "%%f" -status
echo.
pause
