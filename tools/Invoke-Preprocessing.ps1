function Invoke-Preprocessing {
    <#
        .SYNOPSIS
        Safely preprocesses text/code files only.

        .DESCRIPTION
        Applies basic formatting rules to supported text/code files inside WorkingDir.
        Binary assets are intentionally skipped to avoid corrupting files like .png/.ico.

    #>

    param (
        [Parameter(Mandatory, Position=1)]
        [ValidateScript({ [System.IO.Path]::IsPathRooted($_) })]
        [string]$WorkingDir,

        [Parameter(Position=2)]
        [string[]]$ExcludedFiles = @(),

        [Parameter(Mandatory, Position=3)]
        [string]$ProgressStatusMessage,

        [Parameter(Position=4)]
        [string]$ProgressActivity = "Preprocessing"
    )

    if (-not (Test-Path -LiteralPath $WorkingDir -PathType Container)) {
        throw "[Invoke-Preprocessing] Invalid Parameter Value for 'WorkingDir', passed value: '$WorkingDir'. Either the path is a File or Non-Existing/Invalid, please double check your code."
    }

    $supportedExtensions = @(
        '.ps1', '.psm1', '.psd1',
        '.xaml', '.xml',
        '.json', '.yaml', '.yml',
        '.md', '.txt',
        '.ts', '.tsx', '.js', '.jsx',
        '.css', '.scss', '.html'
    )

    $excludedFullPaths = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    $excludedPatterns = [System.Collections.Generic.List[string]]::new()

    foreach ($excludedFile in $ExcludedFiles) {
        if ([string]::IsNullOrWhiteSpace($excludedFile)) { continue }

        if ($excludedFile.Contains('*') -or $excludedFile.Contains('?')) {
            $excludedPatterns.Add($excludedFile) | Out-Null
            continue
        }

        $relativeValue = $excludedFile -replace '^[.\\\/]+', ''
        $fullPath = Join-Path $WorkingDir $relativeValue

        if ($excludedFile -match '[\\\/]$') {
            if (Test-Path -LiteralPath $fullPath -PathType Container) {
                Get-ChildItem -LiteralPath $fullPath -Recurse -File -Force -ErrorAction SilentlyContinue | ForEach-Object {
                    $excludedFullPaths.Add($_.FullName) | Out-Null
                }
            }
            continue
        }

        if (Test-Path -LiteralPath $fullPath -PathType Leaf) {
            $excludedFullPaths.Add((Resolve-Path -LiteralPath $fullPath).Path) | Out-Null
        }
    }

    [System.Collections.ArrayList]$files = @(
        Get-ChildItem -LiteralPath $WorkingDir -Recurse -File -Force | Where-Object {
            $extension = [System.IO.Path]::GetExtension($_.FullName)
            if ($supportedExtensions -notcontains $extension) { return $false }
            if ($excludedFullPaths.Contains($_.FullName)) { return $false }

            foreach ($pattern in $excludedPatterns) {
                if ($_.Name -like $pattern -or $_.FullName -like $pattern) {
                    return $false
                }
            }

            return $true
        }
    )

    $hashFilePath = Join-Path -Path $WorkingDir -ChildPath ".preprocessor_hashes.json"

    $existingHashes = @{}
    if (Test-Path -LiteralPath $hashFilePath) {
        $fileContent = Get-Content -LiteralPath $hashFilePath -Raw | ConvertFrom-Json
        foreach ($property in $fileContent.PSObject.Properties) {
            $existingHashes[$property.Name] = $property.Value
        }
    }

    $newHashes = @{}
    $changedFiles = @()
    $hashingAlgorithm = "MD5"

    foreach ($file in $files) {
        $hash = Get-FileHash -LiteralPath $file.FullName -Algorithm $hashingAlgorithm | Select-Object -ExpandProperty Hash
        $newHashes[$file.FullName] = $hash

        if ($existingHashes.ContainsKey($file.FullName) -and $existingHashes[$file.FullName] -eq $hash) {
            continue
        }

        $changedFiles += $file.FullName
    }

    $numOfFiles = $changedFiles.Count
    Write-Debug "[Invoke-Preprocessing] Files Changed: $numOfFiles"

    if ($numOfFiles -eq 0) {
        Write-Debug "[Invoke-Preprocessing] Found 0 Files to Preprocess inside 'WorkingDir' Directory : '$WorkingDir'."
        return
    }

    for ($i = 0; $i -lt $numOfFiles; $i++) {
        $fullFileName = $changedFiles[$i]

        (
            Get-Content -LiteralPath $fullFileName
        ).TrimEnd() `
            -replace '\t', '    ' `
            -replace '\)\s*\{', ') {' `
            -replace '(?<keyword>if|for|foreach)\s*(?<condition>\([.*?]\))\s*\{', '${keyword} ${condition} {' `
            -replace '\}\s*elseif\s*(?<condition>\([.*?]\))\s*\{', '} elseif ${condition} {' `
            -replace '\}\s*else\s*\{', '} else {' `
            -replace 'Try\s*\{', 'try {' `
            -replace 'Catch\s*\{', 'catch {' `
            -replace '\}\s*Catch', '} catch' `
            -replace '\}\s*Catch\s*(?<exceptions>(\[.*?\]\s*(\,)?\s*)+)\s*\{', '} catch ${exceptions} {' `
            -replace '\}\s*Catch\s*(?<exceptions>\[.*?\])\s*\{', '} catch ${exceptions} {' `
            -replace '(?<parameter_type>\[[^$0-9]+\])\s*(?<str_after_type>\$.*?)', '${parameter_type}${str_after_type}' |
            Set-Content -LiteralPath $fullFileName

        $newHashes[$fullFileName] = Get-FileHash -LiteralPath $fullFileName -Algorithm $hashingAlgorithm | Select-Object -ExpandProperty Hash

        Write-Progress -Activity $ProgressActivity -Status "$ProgressStatusMessage - Finished $i out of $numOfFiles" -PercentComplete (($i / $numOfFiles) * 100)
    }

    Write-Progress -Activity $ProgressActivity -Status "$ProgressStatusMessage - Finished Task Successfully" -Completed
    $newHashes | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $hashFilePath
}
