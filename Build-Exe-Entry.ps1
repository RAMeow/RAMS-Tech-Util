param(
    [string]$Config,
    [switch]$Run,
    [switch]$NoUI,
    [switch]$Offline
)

$ErrorActionPreference = "Stop"

function Test-IsAdmin {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Get-AppRoot {
    $baseDir = [System.AppDomain]::CurrentDomain.BaseDirectory
    if (-not [string]::IsNullOrWhiteSpace($baseDir)) {
        return $baseDir.TrimEnd('\')
    }

    if ($PSScriptRoot) {
        return $PSScriptRoot.TrimEnd('\')
    }

    throw "Could not resolve application folder."
}

function Get-SelfPath {
    if ($env:PS2EXE) {
        return [System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName
    }

    if ($PSCommandPath) {
        return $PSCommandPath
    }

    if ($MyInvocation.MyCommand.Path) {
        return $MyInvocation.MyCommand.Path
    }

    throw "Could not resolve current launcher path."
}

try {
    Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force

    $root = Get-AppRoot
    Set-Location $root

    if (-not (Test-IsAdmin)) {
        $selfPath = Get-SelfPath

        $argList = @()
        if ($Config) { $argList += @('-Config', "`"$Config`"") }
        if ($Run) { $argList += '-Run' }
        if ($NoUI) { $argList += '-NoUI' }
        if ($Offline) { $argList += '-Offline' }

        if ($selfPath.ToLower().EndsWith(".exe")) {
            Start-Process -FilePath $selfPath -Verb RunAs -WorkingDirectory $root -ArgumentList ($argList -join ' ')
        }
        else {
            $psArgs = @(
                '-NoProfile',
                '-ExecutionPolicy', 'Bypass',
                '-File', "`"$selfPath`""
            ) + $argList

            Start-Process -FilePath 'powershell.exe' -Verb RunAs -WorkingDirectory $root -ArgumentList ($psArgs -join ' ')
        }

        exit
    }

    $Host.UI.RawUI.WindowTitle = "RAM Tech Utility"

    $compiled = Join-Path $root 'winutil.ps1'
    $compileScript = Join-Path $root 'Compile.ps1'

    if (-not (Test-Path $compiled)) {
        if (-not (Test-Path $compileScript)) {
            throw "Could not find Compile.ps1 in: $root"
        }

        Write-Host "Compiling RAM Tech Utility from source..." -ForegroundColor Cyan
        & $compileScript

        if ($LASTEXITCODE -and $LASTEXITCODE -ne 0) {
            throw "Compile.ps1 exited with code $LASTEXITCODE"
        }
    }

    if (-not (Test-Path $compiled)) {
        throw "RAM Tech Utility could not create winutil.ps1 during startup."
    }

    $runArgs = @()
    if ($Config) { $runArgs += @('-Config', $Config) }
    if ($Run) { $runArgs += '-Run' }
    if ($NoUI) { $runArgs += '-NoUI' }
    if ($Offline) { $runArgs += '-Offline' }

    & $compiled @runArgs
}
catch {
    try {
        Add-Type -AssemblyName System.Windows.Forms
        [System.Windows.Forms.MessageBox]::Show(
            $_.Exception.Message,
            "RAM Tech Utility",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        ) | Out-Null
    }
    catch {
        Write-Host $_.Exception.Message
        Read-Host "Press Enter to exit"
    }
}
