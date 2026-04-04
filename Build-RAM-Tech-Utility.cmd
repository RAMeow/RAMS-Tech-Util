@echo off
setlocal

cd /d "%~dp0"

echo ==========================================
echo   RAM Tech Utility EXE Builder
echo ==========================================
echo.

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Build-RAM-Tech-Utility.ps1"

if errorlevel 1 (
  echo.
  echo Build failed.
  pause
  exit /b 1
)

echo.
echo Build complete.
pause
exit /b 0
