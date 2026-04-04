@echo off
setlocal

cd /d "%~dp0"

echo ==========================================
echo   RAM Tech Utility EXE Builder
echo ==========================================
echo.

set "ROOT=%~dp0"
set "PS1=%ROOT%Build-Exe-Entry.ps1"
set "ICON=%ROOT%logo.ico"
set "OUT=%ROOT%RAM-Tech-Utility.exe"
set "PAYLOAD=%ROOT%winutil.ps1"

if not exist "%PS1%" (
  echo ERROR: Missing Build-Exe-Entry.ps1
  pause
  exit /b 1
)

if not exist "%ICON%" (
  echo ERROR: Missing logo.ico
  pause
  exit /b 1
)

if not exist "%PAYLOAD%" (
  echo ERROR: Missing winutil.ps1
  echo Run the normal launcher once first so winutil.ps1 is generated.
  pause
  exit /b 1
)

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force; ^
   Import-Module ps2exe; ^
   Invoke-PS2EXE ^
     -inputFile '%PS1%' ^
     -outputFile '%OUT%' ^
     -iconFile '%ICON%' ^
     -noConsole ^
     -embedFiles @{ ^
       \"$env:LOCALAPPDATA\RAM-Tech-Utility\winutil.ps1\" = '%PAYLOAD%' ^
     } ^
     -verbose"

if errorlevel 1 (
  echo.
  echo Build failed.
  pause
  exit /b 1
)

echo.
echo Build complete:
echo %OUT%
pause
exit /b 0
