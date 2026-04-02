@echo off
setlocal
title RAM Tech Utility
cd /d "%~dp0"
whoami /groups | find "S-1-5-32-544" >nul
if errorlevel 1 (
  powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process PowerShell -Verb RunAs -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-File','%~dp0Start-RAM-Tech-Utility.ps1'"
  exit /b
)
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Start-RAM-Tech-Utility.ps1"
