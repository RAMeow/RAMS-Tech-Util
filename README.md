# RAM Tech Utility

RAM Tech Utility is a customized Windows utility toolkit based on the WinUtil foundation, adapted for RAM’S COMPUTER REPAIR workflows, branding, and tooling.

## What this repo contains

This repository contains the **source files** for RAM Tech Utility, including:

- PowerShell launcher scripts
- compile/build scripts
- XAML UI files
- configuration files
- functions and helper modules
- branding assets

This repo is meant to track **source**, not generated output.

---

## Main launch files

### `Start-RAM-Tech-Utility.bat`
Simple Windows launcher for normal use.

### `Start-RAM-Tech-Utility.ps1`
PowerShell launcher that starts the utility with elevation handling.

### `Compile.ps1`
Builds the generated runtime file used by the tool.

### `Build-Exe-Entry.ps1`
Entry script used to create the EXE launcher build.

### `Build-RAM-Tech-Utility.ps1`
Main EXE build script.

### `Build-RAM-Tech-Utility.cmd`
Double-click wrapper that runs the PowerShell EXE build script.

---

## Normal source launch

To run the tool from source:

1. Open the repo folder
2. Run:

```powershell
.\Start-RAM-Tech-Utility.ps1
