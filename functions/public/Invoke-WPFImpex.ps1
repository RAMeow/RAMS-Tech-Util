function Invoke-WPFImpex {
    <#

    .SYNOPSIS
        Handles importing and exporting of the selected apps, tweaks, toggles, and features.

    .PARAMETER type
        Indicates whether to 'import' or 'export'

    .PARAMETER Config
        Optional config path or URL to import from, or file path to export to

    .EXAMPLE
        Invoke-WPFImpex -type "export"

    #>
    param(
        $type,
        $Config = $null
    )

    function ConfigDialog {
        if (-not $Config) {
            switch ($type) {
                "export" { $FileBrowser = New-Object System.Windows.Forms.SaveFileDialog }
                "import" { $FileBrowser = New-Object System.Windows.Forms.OpenFileDialog }
            }

            $FileBrowser.InitialDirectory = [Environment]::GetFolderPath('Desktop')
            $FileBrowser.Filter = "JSON Files (*.json)|*.json"
            $FileBrowser.ShowDialog() | Out-Null

            if ([string]::IsNullOrWhiteSpace($FileBrowser.FileName)) {
                return $null
            }
            else {
                return $FileBrowser.FileName
            }
        }
        else {
            return $Config
        }
    }

    switch ($type) {
        "export" {
            try {
                $Config = ConfigDialog

                if ($Config) {
                    $allConfs = ($sync.selectedApps + $sync.selectedTweaks + $sync.selectedToggles + $sync.selectedFeatures) |
                        ForEach-Object { [string]$_ }

                    if (-not $allConfs -or $allConfs.Count -eq 0) {
                        [System.Windows.MessageBox]::Show(
                            "No settings are selected to export. Please select at least one app, tweak, toggle, or feature before exporting.",
                            "Nothing to Export",
                            "OK",
                            "Warning"
                        ) | Out-Null
                        return
                    }

                    $jsonFile = $allConfs | ConvertTo-Json
                    $jsonFile | Out-File $Config -Force -Encoding utf8

                    try {
                        Set-Clipboard -Value $Config
                    }
                    catch {
                        Write-Warning "Export succeeded, but the file path could not be copied to the clipboard."
                    }

                    [System.Windows.MessageBox]::Show(
                        "Configuration exported successfully.`r`n`r`nSaved to:`r`n$Config`r`n`r`nThe file path has been copied to the clipboard.",
                        "Export Complete",
                        "OK",
                        "Information"
                    ) | Out-Null
                }
            }
            catch {
                Write-Error "An error occurred while exporting: $_"
            }
        }

        "import" {
            try {
                $Config = ConfigDialog

                if ($Config) {
                    try {
                        if ($Config -match '^https?://') {
                            $jsonFile = (Invoke-WebRequest "$Config").Content | ConvertFrom-Json
                        }
                        else {
                            $jsonFile = Get-Content $Config | ConvertFrom-Json
                        }
                    }
                    catch {
                        Write-Error "Failed to load the JSON file from the specified path or URL: $_"
                        return
                    }

                    $flattenedJson = $jsonFile

                    if (-not $flattenedJson) {
                        [System.Windows.MessageBox]::Show(
                            "The selected file contains no settings to import. No changes have been made.",
                            "Empty Configuration",
                            "OK",
                            "Warning"
                        ) | Out-Null
                        return
                    }

                    # Clear all existing selections before importing so the import replaces
                    # the current state rather than merging with it
                    $sync.selectedApps = [System.Collections.Generic.List[string]]::new()
                    $sync.selectedTweaks = [System.Collections.Generic.List[string]]::new()
                    $sync.selectedToggles = [System.Collections.Generic.List[string]]::new()
                    $sync.selectedFeatures = [System.Collections.Generic.List[string]]::new()

                    Update-WinUtilSelections -flatJson $flattenedJson

                    if (-not $PARAM_NOUI) {
                        # Prevent toggle handlers from firing while restoring imported UI state
                        $sync.ImportInProgress = $true
                        try {
                            Reset-WPFCheckBoxes -doToggles $true
                        }
                        finally {
                            $sync.ImportInProgress = $false
                        }
                    }

                    [System.Windows.MessageBox]::Show(
                        "Configuration imported successfully.",
                        "Import Complete",
                        "OK",
                        "Information"
                    ) | Out-Null
                }
            }
            catch {
                Write-Error "An error occurred while importing: $_"
            }
        }
    }
}
