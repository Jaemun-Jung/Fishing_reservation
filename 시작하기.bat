@echo off
cd /d "%~dp0"
echo.
echo   Fishing seat monitor is running.
echo   Close this window to stop. (checks every 5 minutes)
echo.
:loop
for %%f in (*.ps1) do powershell -NoProfile -File "%%f"
timeout /t 300 /nobreak >nul
goto loop
