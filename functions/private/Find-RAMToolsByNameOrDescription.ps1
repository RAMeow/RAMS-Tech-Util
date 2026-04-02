function Find-RAMToolsByNameOrDescription {
    <#
    .SYNOPSIS
        Filters RAM Tools cards and actions by name or description.
    #>
    param(
        [string]$SearchString = ""
    )

    $term = if ($null -eq $SearchString) { "" } else { $SearchString.Trim().ToLowerInvariant() }

    $entries = @(
        @{ Border = 'WPFRAMRepairsCard';      Name = 'Repairs';        Description = 'repair routines quick fixes technician workflows troubleshooting and cleanup'; Button = 'WPFRAMRepairsScaffold' },
        @{ Border = 'WPFRAMDiagnosticsCard';  Name = 'Diagnostics';    Description = 'hardware checks software health intake diagnostics system checks'; Button = 'WPFRAMDiagnosticsScaffold' },
        @{ Border = 'WPFRAMBusinessCard';     Name = 'Business Tools'; Description = 'client setup bundles workstation prep business service presets'; Button = 'WPFRAMBusinessScaffold' },
        @{ Border = $null;                    Name = 'Open RAM Module Folder'; Description = 'open ram module folder files and overrides'; Button = 'WPFRAMOpenModuleFolder' },
        @{ Border = $null;                    Name = 'Show RAM Module Roadmap'; Description = 'show ram module roadmap plans and next steps'; Button = 'WPFRAMShowRoadmap' }
    )

    foreach ($entry in $entries) {
        $isMatch = [string]::IsNullOrWhiteSpace($term) -or
            $entry.Name.ToLowerInvariant().Contains($term) -or
            $entry.Description.ToLowerInvariant().Contains($term)

        if ($entry.Border -and $sync.ContainsKey($entry.Border) -and $sync[$entry.Border]) {
            $sync[$entry.Border].Visibility = if ($isMatch) { 'Visible' } else { 'Collapsed' }
        }

        if ($sync.ContainsKey($entry.Button) -and $sync[$entry.Button]) {
            $sync[$entry.Button].Visibility = if ($isMatch) { 'Visible' } else { 'Collapsed' }
        }
    }

    if ($sync.ContainsKey('WPFRAMActionPanel') -and $sync.WPFRAMActionPanel) {
        $visibleButtons = @($sync.WPFRAMActionPanel.Children | Where-Object { $_.Visibility -eq 'Visible' }).Count
        $sync.WPFRAMActionPanel.Visibility = if ($visibleButtons -gt 0) { 'Visible' } else { 'Collapsed' }
    }
}
