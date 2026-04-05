# RAM Tech Utility bootstrap installer/launcher
# Host this file at:
# https://www.ramscomputerrepair.net/ram.ps1
#
# Recommended usage:
# iwr "https://www.ramscomputerrepair.net/ram.ps1" -OutFile "$env:TEMP\ram.ps1"; & powershell -ExecutionPolicy Bypass -File "$env:TEMP\ram.ps1"
#
# Alternate supported usage:
# irm "https://www.ramscomputerrepair.net/ram.ps1" | iex

[CmdletBinding()]
param(
    [string]$ReleaseZipUrl = "https://github.com/RAMeow/RAMS-Tech-Util/archive/refs/heads/main.zip",
    [string]$InstallRoot = (Join-Path $env:LOCALAPPDATA "RAM-Tech-Utility"),
    [switch]$ForceRedownload
)

$ErrorActionPreference = 'Stop'

function Write-RAMStatus {
    param([string]$Message)
    Write-Host "[RAM Tech Utility]$Message"
}

function Test-IsAdmin {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Get-ScriptPath {
    if ($PSCommandPath) { return $PSCommandPath }
    if ($MyInvocation.MyCommand.Path) { return $MyInvocation.MyCommand.Path }
    return $null
}

function Get-ScriptContentForSelfSave {
    $scriptPath = Get-ScriptPath
    if ($scriptPath -and (Test-Path $scriptPath)) {
        return Get-Content -Path $scriptPath -Raw
    }

    $definition = $MyInvocation.MyCommand.Definition
    if (-not [string]::IsNullOrWhiteSpace($definition)) {
        return $definition
    }

    throw "Could not determine bootstrap script content for self-save."
}

function Ensure-ScriptFile {
    $scriptPath = Get-ScriptPath
    if ($scriptPath -and (Test-Path $scriptPath)) {
        return $scriptPath
    }

    $tempScriptPath = Join-Path $env:TEMP "ram-bootstrap.ps1"
    $scriptContent = Get-ScriptContentForSelfSave
    Set-Content -Path $tempScriptPath -Value $scriptContent -Encoding UTF8 -Force
    return $tempScriptPath
}

function Restart-Elevated {
    param([string]$ScriptPath)

    if (-not $ScriptPath) {
        throw "Unable to self-elevate because the bootstrap script path is unknown."
    }

    $argList = @(
        '-NoProfile'
        '-ExecutionPolicy', 'Bypass'
        '-File', ('"{0}"' -f $ScriptPath)
        '-ReleaseZipUrl', ('"{0}"' -f $ReleaseZipUrl)
        '-InstallRoot', ('"{0}"' -f $InstallRoot)
    )

    if ($ForceRedownload) {
        $argList += '-ForceRedownload'
    }

    Write-RAMStatus "Requesting Administrator elevation..."
    Start-Process -FilePath 'powershell.exe' -Verb RunAs -ArgumentList ($argList -join ' ')
    exit
}

function Get-LauncherPath {
    param([string]$Root)

    $preferredNames = @(
        "Start-RAM-Tech-Utility.ps1",
        "RAM-Tech-Utility.exe"
    )

    foreach ($name in $preferredNames) {
        $directPath = Join-Path $Root $name
        if (Test-Path $directPath) {
            return $directPath
        }

        $nested = Get-ChildItem -Path $Root -Filter $name -Recurse -File -ErrorAction SilentlyContinue |
            Select-Object -First 1

        if ($nested) {
            return $nested.FullName
        }
    }

    return $null
}

function Invoke-Download {
    param(
        [string]$Url,
        [string]$Destination
    )

    Write-RAMStatus "Downloading latest package..."
    Invoke-WebRequest -Uri $Url -OutFile $Destination -UseBasicParsing
}

function Expand-Package {
    param(
        [string]$ZipPath,
        [string]$Destination
    )

    if (Test-Path $Destination) {
        Get-ChildItem -Path $Destination -Force -ErrorAction SilentlyContinue |
            Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    }
    else {
        New-Item -Path $Destination -ItemType Directory -Force | Out-Null
    }

    Write-RAMStatus "Extracting package..."
    Expand-Archive -Path $ZipPath -DestinationPath $Destination -Force
}

function Start-RAMLauncher {
    param([string]$Path)

    Write-RAMStatus "Starting RAM Tech Utility..."

    $extension = [System.IO.Path]::GetExtension($Path)

    switch ($extension.ToLowerInvariant()) {
        ".ps1" {
            & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $Path
        }
        ".exe" {
            Start-Process -FilePath $Path -WorkingDirectory (Split-Path $Path -Parent)
        }
        default {
            throw "Unsupported launcher type: $Path"
        }
    }
}

try {
    Write-RAMStatus "Bootstrap starting..."

    $scriptPath = Ensure-ScriptFile

    if (-not (Test-IsAdmin)) {
        Restart-Elevated -ScriptPath $scriptPath
    }

    $tempZip = Join-Path $env:TEMP 'RAM-Tech-Utility-latest.zip'
    New-Item -Path $InstallRoot -ItemType Directory -Force | Out-Null

    $launcherPath = Get-LauncherPath -Root $InstallRoot

    if ($ForceRedownload -or -not $launcherPath) {
        Invoke-Download -Url $ReleaseZipUrl -Destination $tempZip
        Expand-Package -ZipPath $tempZip -Destination $InstallRoot
        $launcherPath = Get-LauncherPath -Root $InstallRoot
    }
    else {
        Write-RAMStatus "Existing install found. Using local copy."
    }

    if (-not $launcherPath) {
        throw "Could not find Start-RAM-Tech-Utility.ps1 or RAM-Tech-Utility.exe after extraction. Check the package contents."
    }

    Start-RAMLauncher -Path $launcherPath
}
catch {
    Write-Host ""
    Write-Host "RAM Tech Utility bootstrap failed." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Release ZIP URL: $ReleaseZipUrl"
    Write-Host "Install Root:    $InstallRoot"
    throw
}
