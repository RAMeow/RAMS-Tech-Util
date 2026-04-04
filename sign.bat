@echo off
setlocal

cd /d "%~dp0"

echo ==========================================
echo   RAM Tech Utility EXE Signing
echo ==========================================
echo.

set "EXE=%~dp0RAM-Tech-Utility.exe"

if not exist "%EXE%" (
  echo ERROR: RAM-Tech-Utility.exe was not found.
  echo Build the EXE first before signing it.
  pause
  exit /b 1
)

where signtool >nul 2>&1
if errorlevel 1 (
  echo ERROR: signtool was not found in PATH.
  echo Install the Windows SDK signing tools or open the correct developer shell.
  pause
  exit /b 1
)

signtool sign /fd SHA256 /a /tr http://timestamp.digicert.com /td SHA256 "%EXE%"

if errorlevel 1 (
  echo.
  echo Signing failed.
  pause
  exit /b 1
)

echo.
echo Signing complete:
echo %EXE%
pause
exit /b 0
