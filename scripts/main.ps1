# Create enums
Add-Type @"
public enum PackageManagers
{
    Winget,
    Choco
}
"@

# SPDX-License-Identifier: MIT
# Set the maximum number of threads for the RunspacePool to the number of threads on the machine
$maxthreads = [int]$env:NUMBER_OF_PROCESSORS

# Create a new session state for parsing variables into our runspace
$hashVars = New-Object System.Management.Automation.Runspaces.SessionStateVariableEntry -ArgumentList 'sync', $sync, $null
$debugVar = New-Object System.Management.Automation.Runspaces.SessionStateVariableEntry -ArgumentList 'DebugPreference', $DebugPreference, $null
$uiVar = New-Object System.Management.Automation.Runspaces.SessionStateVariableEntry -ArgumentList 'PARAM_NOUI', $PARAM_NOUI, $null
$offlineVar = New-Object System.Management.Automation.Runspaces.SessionStateVariableEntry -ArgumentList 'PARAM_OFFLINE', $PARAM_OFFLINE, $null
$InitialSessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()

# Add the variables to the session state
$InitialSessionState.Variables.Add($hashVars)
$InitialSessionState.Variables.Add($debugVar)
$InitialSessionState.Variables.Add($uiVar)
$InitialSessionState.Variables.Add($offlineVar)

# Get every private function and add them to the session state
$functions = Get-ChildItem function:\ | Where-Object { $_.Name -imatch 'winutil|WPF|RAMS' }
foreach ($function in $functions) {
    $functionDefinition = Get-Content function:\$($function.Name)
    $functionEntry = New-Object System.Management.Automation.Runspaces.SessionStateFunctionEntry -ArgumentList $function.Name, $functionDefinition
    $InitialSessionState.Commands.Add($functionEntry)
}

# Create the runspace pool
$sync.runspace = [runspacefactory]::CreateRunspacePool(
    1,
    $maxthreads,
    $InitialSessionState,
    $Host
)

# Open the RunspacePool instance
$sync.runspace.Open()

# Exception classes are provided elsewhere in the build.

# Load the configuration files
$sync.configs.applicationsHashtable = @{}
$sync.configs.applications.PSObject.Properties | ForEach-Object {
    $sync.configs.applicationsHashtable[$_.Name] = $_.Value
}

Set-Preferences

if ($PARAM_NOUI) {
    Show-RAMSLogo
    if ($PARAM_CONFIG -and -not [string]::IsNullOrWhiteSpace($PARAM_CONFIG)) {
        Write-Host "Running config file tasks..."
        Invoke-WPFImpex -type "import" -Config $PARAM_CONFIG

        if ($PARAM_RUN) {
            Invoke-WinUtilAutoRun
        }
        else {
            Write-Host "Did you forget to add '--Run'?"
        }

        $sync.runspace.Dispose()
        $sync.runspace.Close()
        [System.GC]::Collect()
        Stop-Transcript
        exit 1
    }
    else {
        Write-Host "Cannot automatically run without a config file provided."
        $sync.runspace.Dispose()
        $sync.runspace.Close()
        [System.GC]::Collect()
        Stop-Transcript
        exit 1
    }
}

$inputXML = $inputXML -replace 'mc:Ignorable="d"', '' -replace "x:N", 'N' -replace '^<Win.*', '<Window'

[void][System.Reflection.Assembly]::LoadWithPartialName('presentationframework')
[xml]$XAML = $inputXML

# Read the XAML file
$readerOperationSuccessful = $false
$reader = (New-Object System.Xml.XmlNodeReader $xaml)

try {
    $sync["Form"] = [Windows.Markup.XamlReader]::Load($reader)
    $readerOperationSuccessful = $true
}
catch [System.Management.Automation.MethodInvocationException] {
    Write-Host "We ran into a problem with the XAML code. Check the syntax for this control..." -ForegroundColor Red
    Write-Host $error[0].Exception.Message -ForegroundColor Red

    if ($error[0].Exception.Message -like "*button*") {
        Write-Host "Ensure your <button in the `$inputXML does NOT have a Click=ButtonClick property. PS can't handle this." -ForegroundColor Red
    }
}
catch {
    Write-Host "Unable to load Windows.Markup.XamlReader. Double-check syntax and ensure .NET is installed." -ForegroundColor Red
}

if (-not $readerOperationSuccessful) {
    Write-Host "Failed to parse XAML content using Windows.Markup.XamlReader Load." -ForegroundColor Red
    Write-Host "Quitting RAM Tech Utility..." -ForegroundColor Red
    $sync.runspace.Dispose()
    $sync.runspace.Close()
    [System.GC]::Collect()
    exit 1
}

# Setup the Window to listen for Windows theme change events and update the RAM Tech Utility theme
$lastThemeChangeTime = [datetime]::MinValue
$debounceInterval = [timespan]::FromSeconds(2)

$sync.Form.Add_Loaded({
    $interopHelper = New-Object System.Windows.Interop.WindowInteropHelper $sync.Form
    $hwndSource = [System.Windows.Interop.HwndSource]::FromHwnd($interopHelper.Handle)
    $hwndSource.AddHook({
        param (
            [System.IntPtr]$hwnd,
            [int]$msg,
            [System.IntPtr]$wParam,
            [System.IntPtr]$lParam,
            [ref]$handled
        )

        if (($msg -eq 0x001A) -and $sync.ThemeButton.Content -eq [char]0xF08C) {
            $currentTime = [datetime]::Now
            if ($currentTime - $lastThemeChangeTime -gt $debounceInterval) {
                Invoke-WinutilThemeChange -theme "Auto"
                $script:lastThemeChangeTime = $currentTime
                $handled = $true
            }
        }

        return 0
    })
})

Invoke-WinutilThemeChange -theme $sync.preferences.theme

# Build UI
Invoke-WPFUIElements -configVariable $sync.configs.appnavigation -targetGridName "appscategory" -columncount 1
Initialize-WPFUI -targetGridName "appscategory"

Initialize-WPFUI -targetGridName "appspanel"

Invoke-WPFUIElements -configVariable $sync.configs.tweaks -targetGridName "tweakspanel" -columncount 2
Invoke-WPFUIElements -configVariable $sync.configs.feature -targetGridName "featurespanel" -columncount 2

# Store form objects in PowerShell
$xaml.SelectNodes("//*[@Name]") | ForEach-Object {
    $sync["$($psitem.Name)"] = $sync["Form"].FindName($psitem.Name)
}


# RAM Repairs helpers and direct button handlers
$ramRepairButtonNames = @(
    "WPFRAMRepairNewIntake",
    "WPFRAMRepairMalware",
    "WPFRAMRepairTuneup",
    "WPFRAMRepairWindowsFix",
    "WPFRAMRepairSaveSession",
    "WPFRAMRepairClearSession",
    "WPFRAMRepairMarkComplete",
    "WPFRAMRepairMarkReadyPickup",
    "WPFRAMRepairCloseTicket",
    "WPFRAMGenerateTicketId"
)

function Get-RAMRepairFieldValue {
    param(
        [Parameter(Mandatory)]
        [string]$ControlName
    )

    if ($sync[$ControlName] -and $null -ne $sync[$ControlName].Text) {
        return $sync[$ControlName].Text.Trim()
    }

    return ""
}

function Set-RAMRepairFieldValue {
    param(
        [Parameter(Mandatory)]
        [string]$ControlName,
        [string]$Value = ""
    )

    if ($sync[$ControlName] -and $null -ne $sync[$ControlName].Text) {
        $sync[$ControlName].Text = $Value
    }
}

function Get-RAMTicketStatePath {
    $appDataPath = Join-Path ([Environment]::GetFolderPath("LocalApplicationData")) "RAM-Tech-Utility"
    if (-not (Test-Path -LiteralPath $appDataPath)) {
        New-Item -Path $appDataPath -ItemType Directory -Force | Out-Null
    }

    return (Join-Path $appDataPath "ticket-sequence.txt")
}

function New-RAMRepairTicketId {
    $todayStamp = Get-Date -Format "yyyyMMdd"
    $statePath = Get-RAMTicketStatePath
    $lastDate = ""
    $lastNumber = 0

    if (Test-Path -LiteralPath $statePath) {
        try {
            $rawState = (Get-Content -LiteralPath $statePath -ErrorAction Stop | Select-Object -First 1).Trim()
            if ($rawState -match '^(?<date>\d{8})\|(?<num>\d+)$') {
                $lastDate = $matches['date']
                $lastNumber = [int]$matches['num']
            }
        }
        catch {
            $lastDate = ""
            $lastNumber = 0
        }
    }

    if ($lastDate -eq $todayStamp) {
        $nextNumber = $lastNumber + 1
    }
    else {
        $nextNumber = 1
    }

    $stateValue = "{0}|{1}" -f $todayStamp, $nextNumber
    Set-Content -LiteralPath $statePath -Value $stateValue -Encoding UTF8

    return ("RAM-{0}-{1:D3}" -f $todayStamp, $nextNumber)
}

function Ensure-RAMRepairTicketId {
    $ticketId = Get-RAMRepairFieldValue -ControlName "WPFRAMRepairTicketId"
    if ([string]::IsNullOrWhiteSpace($ticketId)) {
        $ticketId = New-RAMRepairTicketId
        Set-RAMRepairFieldValue -ControlName "WPFRAMRepairTicketId" -Value $ticketId
    }

    return $ticketId
}

function Get-RAMRepairSelectedStatus {
    if ($sync.WPFRAMRepairStatusCombo -and $sync.WPFRAMRepairStatusCombo.SelectedItem) {
        return $sync.WPFRAMRepairStatusCombo.SelectedItem.Content.ToString()
    }

    return "Not Started"
}

function Set-RAMRepairStatus {
    param(
        [Parameter(Mandatory)]
        [string]$Status
    )

    if (-not $sync.WPFRAMRepairStatusCombo) {
        return
    }

    foreach ($item in $sync.WPFRAMRepairStatusCombo.Items) {
        if ($item.Content.ToString() -eq $Status) {
            $sync.WPFRAMRepairStatusCombo.SelectedItem = $item
            Update-RAMRepairSummary
            return
        }
    }
}


function Set-RAMRepairChecklistValue {
    param(
        [Parameter(Mandatory)]
        [string]$ControlName,
        [Parameter(Mandatory)]
        [bool]$Value
    )

    if ($sync.ContainsKey($ControlName) -and $null -ne $sync[$ControlName]) {
        $sync[$ControlName].IsChecked = $Value
    }
}

function Clear-RAMRepairChecklist {
    $checklistControlNames = @(
        "WPFRAMRepairChecklistIntake",
        "WPFRAMRepairChecklistBackup",
        "WPFRAMRepairChecklistDiag",
        "WPFRAMRepairChecklistDone",
        "WPFRAMRepairChecklistQC",
        "WPFRAMRepairChecklistPickup"
    )

    foreach ($controlName in $checklistControlNames) {
        if ($sync[$controlName]) {
            $sync[$controlName].IsChecked = $false
        }
    }
}

function Append-RAMRepairNote {
    param(
        [Parameter(Mandatory)]
        [string]$Text
    )

    if (-not $sync.WPFRAMRepairNotes) {
        return
    }

    if ([string]::IsNullOrWhiteSpace($sync.WPFRAMRepairNotes.Text)) {
        $sync.WPFRAMRepairNotes.Text = $Text
    }
    else {
        $sync.WPFRAMRepairNotes.Text += [Environment]::NewLine + [Environment]::NewLine + $Text
    }

    $sync.WPFRAMRepairNotes.CaretIndex = $sync.WPFRAMRepairNotes.Text.Length
    $sync.WPFRAMRepairNotes.ScrollToEnd()
}


function Get-RAMRepairCheckboxValue {
    param([string]$ControlName)

    if ($sync.ContainsKey($ControlName) -and $null -ne $sync[$ControlName]) {
        return [bool]$sync[$ControlName].IsChecked
    }

    return $false
}



function Add-RAMRepairActivity {
    param(
        [Parameter(Mandatory)]
        [string]$Message
    )

    $timestampedMessage = "[{0}] {1}" -f (Get-Date -Format "hh:mm:ss tt"), $Message

    if ($sync.WPFRAMRepairActivityLog -and $null -ne $sync.WPFRAMRepairActivityLog.Text) {
        if ([string]::IsNullOrWhiteSpace($sync.WPFRAMRepairActivityLog.Text)) {
            $sync.WPFRAMRepairActivityLog.Text = $timestampedMessage
        }
        else {
            $sync.WPFRAMRepairActivityLog.Text += [Environment]::NewLine + $timestampedMessage
        }

        $sync.WPFRAMRepairActivityLog.CaretIndex = $sync.WPFRAMRepairActivityLog.Text.Length
        $sync.WPFRAMRepairActivityLog.ScrollToEnd()
    }
}

function Get-RAMRepairChecklistSummary {
    $checkStates = @(
        (Get-RAMRepairCheckboxValue -ControlName "WPFRAMRepairChecklistIntake"),
        (Get-RAMRepairCheckboxValue -ControlName "WPFRAMRepairChecklistBackup"),
        (Get-RAMRepairCheckboxValue -ControlName "WPFRAMRepairChecklistDiag"),
        (Get-RAMRepairCheckboxValue -ControlName "WPFRAMRepairChecklistDone"),
        (Get-RAMRepairCheckboxValue -ControlName "WPFRAMRepairChecklistQC"),
        (Get-RAMRepairCheckboxValue -ControlName "WPFRAMRepairChecklistPickup")
    )

    $completedCount = ($checkStates | Where-Object { $_ }).Count
    return "{0}/6 completed" -f $completedCount
}

function Update-RAMRepairSummary {
    $ticketId = Get-RAMRepairFieldValue -ControlName "WPFRAMRepairTicketId"
    $customer = Get-RAMRepairFieldValue -ControlName "WPFRAMRepairCustomer"
    $phone = Get-RAMRepairFieldValue -ControlName "WPFRAMRepairPhone"
    $device = Get-RAMRepairFieldValue -ControlName "WPFRAMRepairDevice"
    $issue = Get-RAMRepairFieldValue -ControlName "WPFRAMRepairIssue"
    $initialFindings = Get-RAMRepairFieldValue -ControlName "WPFRAMRepairInitialFindings"
    $status = Get-RAMRepairSelectedStatus
    $checklistSummary = Get-RAMRepairChecklistSummary

    if ($sync.WPFRAMRepairSummaryTicketId) {
        $sync.WPFRAMRepairSummaryTicketId.Text = if ([string]::IsNullOrWhiteSpace($ticketId)) { "—" } else { $ticketId }
    }

    if ($sync.WPFRAMRepairSummaryCustomer) {
        $sync.WPFRAMRepairSummaryCustomer.Text = if ([string]::IsNullOrWhiteSpace($customer)) { "—" } else { $customer }
    }

    if ($sync.WPFRAMRepairSummaryPhone) {
        $sync.WPFRAMRepairSummaryPhone.Text = if ([string]::IsNullOrWhiteSpace($phone)) { "—" } else { $phone }
    }

    if ($sync.WPFRAMRepairSummaryDevice) {
        $sync.WPFRAMRepairSummaryDevice.Text = if ([string]::IsNullOrWhiteSpace($device)) { "—" } else { $device }
    }

    if ($sync.WPFRAMRepairSummaryStatus) {
        $sync.WPFRAMRepairSummaryStatus.Text = if ([string]::IsNullOrWhiteSpace($status)) { "Not Started" } else { $status }
    }

    if ($sync.WPFRAMRepairSummaryIssue) {
        $sync.WPFRAMRepairSummaryIssue.Text = if ([string]::IsNullOrWhiteSpace($issue)) { "—" } else { $issue }
    }

    if ($sync.WPFRAMRepairSummaryInitialFindings) {
        $sync.WPFRAMRepairSummaryInitialFindings.Text = if ([string]::IsNullOrWhiteSpace($initialFindings)) { "—" } else { $initialFindings }
    }

    if ($sync.WPFRAMRepairSummaryChecklist) {
        $sync.WPFRAMRepairSummaryChecklist.Text = $checklistSummary
    }

    if ($sync.WPFRAMRepairSummaryLastSave -and [string]::IsNullOrWhiteSpace($sync.WPFRAMRepairSummaryLastSave.Text)) {
        $sync.WPFRAMRepairSummaryLastSave.Text = "Not saved yet"
    }
}

function Reset-RAMRepairSession {
    Clear-RAMRepairChecklist

    Set-RAMRepairFieldValue -ControlName "WPFRAMRepairTicketId" -Value ""
    Set-RAMRepairFieldValue -ControlName "WPFRAMRepairCustomer" -Value ""
    Set-RAMRepairFieldValue -ControlName "WPFRAMRepairPhone" -Value ""
    Set-RAMRepairFieldValue -ControlName "WPFRAMRepairDevice" -Value ""
    Set-RAMRepairFieldValue -ControlName "WPFRAMRepairAccessories" -Value ""
    Set-RAMRepairFieldValue -ControlName "WPFRAMRepairIssue" -Value ""
    Set-RAMRepairFieldValue -ControlName "WPFRAMRepairInitialFindings" -Value ""

    if ($sync.WPFRAMRepairNotes) {
        $sync.WPFRAMRepairNotes.Text = ""
    }

    Set-RAMRepairStatus -Status "Not Started"

    if ($sync.WPFRAMRepairSummaryLastSave) {
        $sync.WPFRAMRepairSummaryLastSave.Text = "Not saved yet"
    }

    if ($sync.WPFRAMRepairActivityLog) {
        $sync.WPFRAMRepairActivityLog.Text = ""
    }

    Add-RAMRepairActivity -Message "Repair session cleared."
    Update-RAMRepairSummary
}

function Save-RAMRepairSession {
    try {
        $desktopPath = [Environment]::GetFolderPath("Desktop")

        $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
        $ticketId = Ensure-RAMRepairTicketId
        $customerSlug = Get-RAMRepairFieldValue -ControlName "WPFRAMRepairCustomer"
        if ([string]::IsNullOrWhiteSpace($customerSlug)) {
            $customerSlug = "walk-in"
        }
        $customerSlug = ($customerSlug -replace '[^a-zA-Z0-9\- ]', '').Trim() -replace '\s+', '-'
        if ([string]::IsNullOrWhiteSpace($customerSlug)) {
            $customerSlug = "walk-in"
        }

        $ticketSlug = ($ticketId -replace '[^a-zA-Z0-9\-]', '').ToLower()
        if ([string]::IsNullOrWhiteSpace($ticketSlug)) {
            $ticketSlug = "no-ticket"
        }

        $savePath = Join-Path $desktopPath ("repair-session-{0}-{1}-{2}.txt" -f $ticketSlug, $customerSlug.ToLower(), $timestamp)

        $customer = Get-RAMRepairFieldValue -ControlName "WPFRAMRepairCustomer"
        $phone = Get-RAMRepairFieldValue -ControlName "WPFRAMRepairPhone"
        $device = Get-RAMRepairFieldValue -ControlName "WPFRAMRepairDevice"
        $accessories = Get-RAMRepairFieldValue -ControlName "WPFRAMRepairAccessories"
        $issue = Get-RAMRepairFieldValue -ControlName "WPFRAMRepairIssue"
        $initialFindings = Get-RAMRepairFieldValue -ControlName "WPFRAMRepairInitialFindings"
        $status = Get-RAMRepairSelectedStatus
        $notes = if ($sync.WPFRAMRepairNotes) { $sync.WPFRAMRepairNotes.Text } else { "" }

        $sessionText = @(
            "RAM'S COMPUTER REPAIR",
            "Repair Session",
            "Saved: $(Get-Date -Format 'yyyy-MM-dd hh:mm:ss tt')",
            "",
            "Ticket / Invoice #: $ticketId",
            "Customer: $customer",
            "Phone / Contact: $phone",
            "Device: $device",
            "Accessories: $accessories",
            "Issue Reported: $issue",
            "Initial Findings: $initialFindings",
            "Status: $status",
            "",
            "Checklist:",
            "- Intake completed: $(Get-RAMRepairCheckboxValue -ControlName 'WPFRAMRepairChecklistIntake')",
            "- Backup advised / confirmed: $(Get-RAMRepairCheckboxValue -ControlName 'WPFRAMRepairChecklistBackup')",
            "- Diagnostics run: $(Get-RAMRepairCheckboxValue -ControlName 'WPFRAMRepairChecklistDiag')",
            "- Repair completed: $(Get-RAMRepairCheckboxValue -ControlName 'WPFRAMRepairChecklistDone')",
            "- QC passed: $(Get-RAMRepairCheckboxValue -ControlName 'WPFRAMRepairChecklistQC')",
            "- Ready for pickup: $(Get-RAMRepairCheckboxValue -ControlName 'WPFRAMRepairChecklistPickup')",
            "",
            "Technician Notes:",
            $(if ([string]::IsNullOrWhiteSpace($notes)) { "(none)" } else { $notes })
        ) -join [Environment]::NewLine

        Set-Content -LiteralPath $savePath -Value $sessionText -Encoding UTF8

        if ($sync.WPFRAMRepairSummaryLastSave) {
            $sync.WPFRAMRepairSummaryLastSave.Text = $savePath
        }

        Add-RAMRepairActivity -Message ("Repair session saved to {0}" -f $savePath)
        Update-RAMRepairSummary

        [System.Windows.MessageBox]::Show(
            "Repair session saved to:`n$savePath",
            "RAM Tech Utility",
            [System.Windows.MessageBoxButton]::OK,
            [System.Windows.MessageBoxImage]::Information
        ) | Out-Null
    }
    catch {
        [System.Windows.MessageBox]::Show(
            "Failed to save repair session.`n$($_.Exception.Message)",
            "RAM Tech Utility",
            [System.Windows.MessageBoxButton]::OK,
            [System.Windows.MessageBoxImage]::Error
        ) | Out-Null
    }
}

if ($sync.WPFRAMRepairTicketId) {
    $sync.WPFRAMRepairTicketId.Add_TextChanged({
        Update-RAMRepairSummary
    })
}

if ($sync.WPFRAMRepairCustomer) {
    $sync.WPFRAMRepairCustomer.Add_TextChanged({
        Update-RAMRepairSummary
    })
}

if ($sync.WPFRAMRepairPhone) {
    $sync.WPFRAMRepairPhone.Add_TextChanged({
        Update-RAMRepairSummary
    })
}

if ($sync.WPFRAMRepairDevice) {
    $sync.WPFRAMRepairDevice.Add_TextChanged({
        Update-RAMRepairSummary
    })
}

if ($sync.WPFRAMRepairIssue) {
    $sync.WPFRAMRepairIssue.Add_TextChanged({
        Update-RAMRepairSummary
    })
}

if ($sync.WPFRAMRepairInitialFindings) {
    $sync.WPFRAMRepairInitialFindings.Add_TextChanged({
        Update-RAMRepairSummary
    })
}

if ($sync.WPFRAMRepairStatusCombo) {
    $sync.WPFRAMRepairStatusCombo.Add_SelectionChanged({
        Update-RAMRepairSummary
    })
}

@(
    "WPFRAMRepairChecklistIntake",
    "WPFRAMRepairChecklistBackup",
    "WPFRAMRepairChecklistDiag",
    "WPFRAMRepairChecklistDone",
    "WPFRAMRepairChecklistQC",
    "WPFRAMRepairChecklistPickup"
) | ForEach-Object {
    if ($sync[$_]) {
        $sync[$_].Add_Click({
            Update-RAMRepairSummary
        })
    }
}

if ($sync.WPFRAMRepairNewIntake) {
    $sync.WPFRAMRepairNewIntake.Add_Click({
        Clear-RAMRepairChecklist

        if ($sync.WPFRAMRepairNotes) {
            $sync.WPFRAMRepairNotes.Text = ""
        }

        Set-RAMRepairStatus -Status "In Intake"

        if ($sync.WPFRAMRepairChecklistIntake) {
            $sync.WPFRAMRepairChecklistIntake.IsChecked = $true
        }

        $openedAt = Get-Date -Format "yyyy-MM-dd hh:mm tt"
        $ticketId = Ensure-RAMRepairTicketId
        $customer = Get-RAMRepairFieldValue -ControlName "WPFRAMRepairCustomer"
        $phone = Get-RAMRepairFieldValue -ControlName "WPFRAMRepairPhone"
        $device = Get-RAMRepairFieldValue -ControlName "WPFRAMRepairDevice"
        $accessories = Get-RAMRepairFieldValue -ControlName "WPFRAMRepairAccessories"
        $issue = Get-RAMRepairFieldValue -ControlName "WPFRAMRepairIssue"
        $initialFindings = Get-RAMRepairFieldValue -ControlName "WPFRAMRepairInitialFindings"

        $sync.WPFRAMRepairNotes.Text = @"
[NEW REPAIR INTAKE]
Ticket / Invoice #: $ticketId
Repair opened: $openedAt
Customer: $customer
Phone / Contact: $phone
Device: $device
Accessories Received: $accessories
Issue Reported: $issue
Initial Findings: $initialFindings
Initial Notes:
"@.Trim()

        $sync.WPFRAMRepairNotes.CaretIndex = $sync.WPFRAMRepairNotes.Text.Length
        $sync.WPFRAMRepairNotes.ScrollToEnd()
        $sync.WPFRAMRepairNotes.Focus()
        Add-RAMRepairActivity -Message "New intake started."
        Update-RAMRepairSummary
    })
}

if ($sync.WPFRAMGenerateTicketId) {
    $sync.WPFRAMGenerateTicketId.Add_Click({
        $ticketId = New-RAMRepairTicketId
        Set-RAMRepairFieldValue -ControlName "WPFRAMRepairTicketId" -Value $ticketId
        Add-RAMRepairActivity -Message ("Generated ticket number {0}." -f $ticketId)
        Update-RAMRepairSummary
    })
}

if ($sync.WPFRAMRepairMalware) {
    $sync.WPFRAMRepairMalware.Add_Click({
        Set-RAMRepairStatus -Status "Repair In Progress"
        Append-RAMRepairNote -Text @"
[MALWARE CLEANUP STARTED]
- Symptoms:
- Browser hijack:
- AV alerts:
- Tools used:
- Outcome:
"@.Trim()
        Add-RAMRepairActivity -Message "Malware cleanup template added."
        Update-RAMRepairSummary
    })
}

if ($sync.WPFRAMRepairTuneup) {
    $sync.WPFRAMRepairTuneup.Add_Click({
        Set-RAMRepairStatus -Status "Repair In Progress"
        Append-RAMRepairNote -Text @"
[PERFORMANCE TUNE-UP]
- Startup review:
- Temp cleanup:
- Update check:
- Drive space:
- RAM usage:
- Result:
"@.Trim()
        Add-RAMRepairActivity -Message "Performance tune-up template added."
        Update-RAMRepairSummary
    })
}

if ($sync.WPFRAMRepairWindowsFix) {
    $sync.WPFRAMRepairWindowsFix.Add_Click({
        Set-RAMRepairStatus -Status "Diagnosing"
        Append-RAMRepairNote -Text @"
[WINDOWS REPAIR]
- Boot issue:
- Update issue:
- Corruption suspected:
- SFC run:
- DISM run:
- Result:
"@.Trim()
        Add-RAMRepairActivity -Message "Windows repair template added."
        Update-RAMRepairSummary
    })
}

if ($sync.WPFRAMRepairSaveSession) {
    $sync.WPFRAMRepairSaveSession.Add_Click({
        Save-RAMRepairSession
    })
}

if ($sync.WPFRAMRepairMarkComplete) {
    $sync.WPFRAMRepairMarkComplete.Add_Click({
        Set-RAMRepairChecklistValue -ControlName "WPFRAMRepairChecklistDone" -Value $true
        Set-RAMRepairStatus -Status "Repair In Progress"
        Append-RAMRepairNote -Text @"
[REPAIR COMPLETED]
Completed: $(Get-Date -Format "yyyy-MM-dd hh:mm tt")
Repair work completed. Ready for QC / final review.
"@.Trim()
        Add-RAMRepairActivity -Message "Repair marked complete."
        Update-RAMRepairSummary
    })
}

if ($sync.WPFRAMRepairMarkReadyPickup) {
    $sync.WPFRAMRepairMarkReadyPickup.Add_Click({
        Set-RAMRepairChecklistValue -ControlName "WPFRAMRepairChecklistDone" -Value $true
        Set-RAMRepairChecklistValue -ControlName "WPFRAMRepairChecklistQC" -Value $true
        Set-RAMRepairChecklistValue -ControlName "WPFRAMRepairChecklistPickup" -Value $true
        Set-RAMRepairStatus -Status "Ready for Pickup"
        Append-RAMRepairNote -Text @"
[READY FOR PICKUP]
Updated: $(Get-Date -Format "yyyy-MM-dd hh:mm tt")
Repair completed, QC passed, and device is ready for pickup.
"@.Trim()
        Add-RAMRepairActivity -Message "Repair marked ready for pickup."
        Update-RAMRepairSummary
    })
}

if ($sync.WPFRAMRepairCloseTicket) {
    $sync.WPFRAMRepairCloseTicket.Add_Click({
        Set-RAMRepairStatus -Status "Closed"
        Append-RAMRepairNote -Text @"
[TICKET CLOSED]
Closed: $(Get-Date -Format "yyyy-MM-dd hh:mm tt")
Ticket closed.
"@.Trim()
        Add-RAMRepairActivity -Message "Ticket closed."
        Update-RAMRepairSummary
    })
}

if ($sync.WPFRAMRepairClearSession) {
    $sync.WPFRAMRepairClearSession.Add_Click({
        Reset-RAMRepairSession
    })
}


if ($sync.WPFRAMQuickTaskMgr) {
    $sync.WPFRAMQuickTaskMgr.Add_Click({
        Start-Process taskmgr.exe
        Add-RAMRepairActivity -Message "Opened Task Manager."
    })
}

if ($sync.WPFRAMQuickDeviceMgr) {
    $sync.WPFRAMQuickDeviceMgr.Add_Click({
        Start-Process devmgmt.msc
        Add-RAMRepairActivity -Message "Opened Device Manager."
    })
}

if ($sync.WPFRAMQuickExplorer) {
    $sync.WPFRAMQuickExplorer.Add_Click({
        Start-Process explorer.exe
        Add-RAMRepairActivity -Message "Opened File Explorer."
    })
}

if ($sync.WPFRAMQuickCMD) {
    $sync.WPFRAMQuickCMD.Add_Click({
        Start-Process cmd.exe
        Add-RAMRepairActivity -Message "Opened Command Prompt."
    })
}

Update-RAMRepairSummary

# Persist Package Manager preference across RAM Tech Utility restarts
$sync.ChocoRadioButton.Add_Checked({
    $sync.preferences.packagemanager = [PackageManagers]::Choco
    Set-Preferences -save
})

$sync.WingetRadioButton.Add_Checked({
    $sync.preferences.packagemanager = [PackageManagers]::Winget
    Set-Preferences -save
})

switch ($sync.preferences.packagemanager) {
    "Choco" { $sync.ChocoRadioButton.IsChecked = $true; break }
    "Winget" { $sync.WingetRadioButton.IsChecked = $true; break }
}

$sync.Keys | ForEach-Object {
    if ($sync.$psitem) {
        $controlType = $sync["$psitem"].GetType() | Select-Object -ExpandProperty Name

        if ($controlType -eq "ToggleButton") {
            $sync["$psitem"].Add_Click({
                [System.Object]$Sender = $args[0]
                Invoke-WPFButton $Sender.Name
            })
        }

        if ($controlType -eq "Button") {
            if ($ramRepairButtonNames -notcontains $psitem) {
                $sync["$psitem"].Add_Click({
                    [System.Object]$Sender = $args[0]
                    Invoke-WPFButton $Sender.Name
                })
            }
        }

        if ($controlType -eq "TextBlock") {
            if ($sync["$psitem"].Name.EndsWith("Link")) {
                $sync["$psitem"].Add_MouseUp({
                    [System.Object]$Sender = $args[0]
                    Start-Process $Sender.ToolTip -ErrorAction Stop
                    Write-Debug "Opening: $($Sender.ToolTip)"
                })
            }
        }
    }
}

# Setup background config
Invoke-WPFRunspace -ScriptBlock {
    try {
        $oldProgressPreference = $ProgressPreference
        $ProgressPreference = "SilentlyContinue"
        $sync.ConfigLoaded = $false
        $sync.ComputerInfo = Get-ComputerInfo
        $sync.ConfigLoaded = $true
    }
    finally {
        $ProgressPreference = $oldProgressPreference
    }
} | Out-Null

# Setup and show the form
Show-RAMSLogo

# Progress bar in taskbaritem
$sync["Form"].TaskbarItemInfo = New-Object System.Windows.Shell.TaskbarItemInfo
Set-WinUtilTaskbaritem -state "None"

# Set the titlebar
$sync["Form"].Title = $sync["Form"].Title + " " + $sync.version

# Set the commands that will run when the form is closed
$sync["Form"].Add_Closing({
    $sync.runspace.Dispose()
    $sync.runspace.Close()
    [System.GC]::Collect()
})

$sync.SearchBarClearButton.Add_Click({
    $sync.SearchBar.Text = ""
    $sync.SearchBarClearButton.Visibility = "Collapsed"
    $sync.SearchBar.Focus()
    $sync.SearchBar.SelectAll()
})

# Keyboard shortcuts
$commonKeyEvents = {
    if ($sync.ProcessRunning -eq $true) {
        return
    }

    switch ($_.Key) {
        "Escape" { $sync.SearchBar.Text = "" }
    }

    if ($_.KeyboardDevice.Modifiers -eq "Alt") {
        $keyEventArgs = $_
        switch ($_.SystemKey) {
            "I" { Invoke-WPFButton "WPFTab1BT"; $keyEventArgs.Handled = $true }
            "T" { Invoke-WPFButton "WPFTab2BT"; $keyEventArgs.Handled = $true }
            "C" { Invoke-WPFButton "WPFTab3BT"; $keyEventArgs.Handled = $true }
            "U" { Invoke-WPFButton "WPFTab4BT"; $keyEventArgs.Handled = $true }
            "W" { Invoke-WPFButton "WPFTab5BT"; $keyEventArgs.Handled = $true }
            "R" { Invoke-WPFButton "WPFTab6BT"; $keyEventArgs.Handled = $true }
        }
    }

    if ($_.KeyboardDevice.Modifiers -eq "Ctrl") {
        switch ($_.Key) {
            "F" { $sync.SearchBar.Focus() }
            "Q" { $this.Close() }
        }
    }
}

$sync["Form"].Add_PreviewKeyDown($commonKeyEvents)

$sync["Form"].Add_MouseLeftButtonDown({
    Invoke-WPFPopup -Action "Hide" -Popups @("Settings", "Theme", "FontScaling")
    $sync["Form"].DragMove()
})

$sync["Form"].Add_MouseDoubleClick({
    if ($_.OriginalSource.Name -eq "NavDockPanel" -or
        $_.OriginalSource.Name -eq "GridBesideNavDockPanel") {
        if ($sync["Form"].WindowState -eq [Windows.WindowState]::Normal) {
            $sync["Form"].WindowState = [Windows.WindowState]::Maximized
        }
        else {
            $sync["Form"].WindowState = [Windows.WindowState]::Normal
        }
    }
})

$sync["Form"].Add_Deactivated({
    Write-Debug "RAM Tech Utility lost focus"
    Invoke-WPFPopup -Action "Hide" -Popups @("Settings", "Theme", "FontScaling")
})

$sync["Form"].Add_ContentRendered({
    Add-Type -AssemblyName System.Windows.Forms
    $primaryScreen = [System.Windows.Forms.Screen]::PrimaryScreen

    if ($primaryScreen) {
        $screenWidth = $primaryScreen.Bounds.Width
        $screenHeight = $primaryScreen.Bounds.Height

        Write-Debug "Primary Monitor Width: $screenWidth pixels"
        Write-Debug "Primary Monitor Height: $screenHeight pixels"

        if ($sync.Form.ActualWidth -gt $screenWidth -or $sync.Form.ActualHeight -gt $screenHeight) {
            Write-Debug "The specified width and/or height is greater than the primary monitor size."
            $sync.Form.Left = 0
            $sync.Form.Top = 0
            $sync.Form.Width = $screenWidth
            $sync.Form.Height = $screenHeight
        }
        else {
            Write-Debug "The specified width and height are within the primary monitor size limits."
        }
    }
    else {
        Write-Debug "Unable to retrieve information about the primary monitor."
    }

    if ($PARAM_OFFLINE) {
        $sync.WPFOfflineBanner.Visibility = [System.Windows.Visibility]::Visible
        $sync.WPFTab1BT.IsEnabled = $false
        $sync.WPFTab1BT.Opacity = 0.5
        $sync.WPFTab1BT.ToolTip = "Internet connection required for installing applications"

        $sync.WPFInstall.IsEnabled = $false
        $sync.WPFUninstall.IsEnabled = $false
        $sync.WPFInstallUpgrade.IsEnabled = $false
        $sync.WPFGetInstalled.IsEnabled = $false

        Write-Host "Offline mode detected - Install tab disabled" -ForegroundColor Yellow
        Invoke-WPFTab "WPFTab2BT"
    }
    else {
        $sync.WPFTab1BT.IsEnabled = $true
        $sync.WPFTab1BT.Opacity = 1.0
        $sync.WPFTab1BT.ToolTip = $null
        Invoke-WPFTab "WPFTab1BT"
    }

    $sync["Form"].Focus()

    if ($PARAM_CONFIG -and -not [string]::IsNullOrWhiteSpace($PARAM_CONFIG)) {
        Write-Host "Running config file tasks..."
        Invoke-WPFImpex -type "import" -Config $PARAM_CONFIG
        if ($PARAM_RUN) {
            Invoke-WinUtilAutoRun
        }
    }
})

# Search timer
$searchBarTimer = New-Object System.Windows.Threading.DispatcherTimer
$searchBarTimer.Interval = [TimeSpan]::FromMilliseconds(300)
$searchBarTimer.IsEnabled = $false

$searchBarTimer.Add_Tick({
    $searchBarTimer.Stop()
    switch ($sync.currentTab) {
        "Install" {
            Find-AppsByNameOrDescription -SearchString $sync.SearchBar.Text
        }
        "Tweaks" {
            Find-TweaksByNameOrDescription -SearchString $sync.SearchBar.Text
        }
        "RAM Tools" {
            Find-RAMToolsByNameOrDescription -SearchString $sync.SearchBar.Text
        }
    }
})

$sync["SearchBar"].Add_TextChanged({
    if ($sync.SearchBar.Text -ne "") {
        $sync.SearchBarClearButton.Visibility = "Visible"
    }
    else {
        $sync.SearchBarClearButton.Visibility = "Collapsed"
    }

    if ($searchBarTimer.IsEnabled) {
        $searchBarTimer.Stop()
    }

    $searchBarTimer.Start()
})

$sync["Form"].Add_Loaded({
    param($e)
    $sync.Form.MinWidth = "1000"
    $sync["Form"].MaxWidth = [Double]::PositiveInfinity
    $sync["Form"].MaxHeight = [Double]::PositiveInfinity
})

$NavLogoPanel = $sync["Form"].FindName("NavLogoPanel")
$NavLogo = (Invoke-WinUtilAssets -Type "logo" -Size 25)

$NavLogoPanel.Children.Clear()
$NavLogoPanel.Children.Add($NavLogo) | Out-Null
$NavLogoPanel.Background = [System.Windows.Media.Brushes]::Transparent
$NavLogoPanel.Cursor = [System.Windows.Input.Cursors]::Hand
$NavLogo.Cursor = [System.Windows.Input.Cursors]::Hand
$NavLogoPanel.ToolTip = "Open RAM'S COMPUTER REPAIR website"
$NavLogo.ToolTip = "Open RAM'S COMPUTER REPAIR website"
$NavLogoPanel.IsHitTestVisible = $true
$NavLogo.IsHitTestVisible = $true

function Open-RAMWebsite {
    try {
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = "https://www.ramscomputerrepair.net/"
        $psi.UseShellExecute = $true
        [System.Diagnostics.Process]::Start($psi) | Out-Null
    }
    catch {
        try {
            Start-Process "explorer.exe" "https://www.ramscomputerrepair.net/" | Out-Null
        }
        catch {
            Write-Host "Failed to open website: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

$NavLogoPanel.Add_PreviewMouseLeftButtonDown({
    param($sender, $e)
    Open-RAMWebsite
    $e.Handled = $true
})

$NavLogo.Add_PreviewMouseLeftButtonDown({
    param($sender, $e)
    Open-RAMWebsite
    $e.Handled = $true
})
$previewHandler = [System.Windows.Input.MouseButtonEventHandler]$OpenRamWebsite
$clickHandler = [System.Windows.Input.MouseButtonEventHandler]$OpenRamWebsite

$sync["logorender"] = (Invoke-WinUtilAssets -Type "Logo" -Size 90 -Render)
$sync["checkmarkrender"] = (Invoke-WinUtilAssets -Type "checkmark" -Size 512 -Render)
$sync["warningrender"] = (Invoke-WinUtilAssets -Type "warning" -Size 512 -Render)

Set-WinUtilTaskbaritem -overlay "logo"

$sync["Form"].Add_Activated({
    Set-WinUtilTaskbaritem -overlay "logo"
})

$sync["ThemeButton"].Add_Click({
    Write-Debug "ThemeButton clicked"
    Invoke-WPFPopup -PopupActionTable @{ "Settings" = "Hide"; "Theme" = "Toggle"; "FontScaling" = "Hide" }
})

$sync["AutoThemeMenuItem"].Add_Click({
    Write-Debug "Auto Theme clicked"
    Invoke-WPFPopup -Action "Hide" -Popups @("Theme")
    Invoke-WinutilThemeChange -theme "Auto"
})

$sync["DarkThemeMenuItem"].Add_Click({
    Write-Debug "Dark Theme clicked"
    Invoke-WPFPopup -Action "Hide" -Popups @("Theme")
    Invoke-WinutilThemeChange -theme "Dark"
})

$sync["LightThemeMenuItem"].Add_Click({
    Write-Debug "Light Theme clicked"
    Invoke-WPFPopup -Action "Hide" -Popups @("Theme")
    Invoke-WinutilThemeChange -theme "Light"
})

$sync["SettingsButton"].Add_Click({
    Write-Debug "SettingsButton clicked"
    Invoke-WPFPopup -PopupActionTable @{ "Settings" = "Toggle"; "Theme" = "Hide"; "FontScaling" = "Hide" }
})

$sync["ImportMenuItem"].Add_Click({
    Write-Debug "Import clicked"
    Invoke-WPFPopup -Action "Hide" -Popups @("Settings")
    Invoke-WPFImpex -type "import"
})

$sync["ExportMenuItem"].Add_Click({
    Write-Debug "Export clicked"
    Invoke-WPFPopup -Action "Hide" -Popups @("Settings")
    Invoke-WPFImpex -type "export"
})

$sync["AboutMenuItem"].Add_Click({
    Write-Debug "About clicked"
    Invoke-WPFPopup -Action "Hide" -Popups @("Settings")

    $authorInfo = @"
Project  : RAM Tech Utility
Edition  : Local utility and system setup toolkit
Version  : $($sync.version)
Support  : Local project build
"@
    Show-CustomDialog -Title "About" -Message $authorInfo
})

$sync["DocumentationMenuItem"].Add_Click({
    Write-Debug "Project Files clicked"
    Invoke-WPFPopup -Action "Hide" -Popups @("Settings")
    Start-Process (Resolve-Path (Join-Path $PSScriptRoot ".."))
})

$sync["SponsorMenuItem"].Add_Click({
    Write-Debug "Credits clicked"
    Invoke-WPFPopup -Action "Hide" -Popups @("Settings")

    $authorInfo = @"
RAM Tech Utility credits

- Project owner: RAM Tech Utility
- Current build: Local rebrand pass
- UI assets and modules: Integrated into this package
"@
    Show-CustomDialog -Title "Credits" -Message $authorInfo -EnableScroll $true
})

# Font scaling
$sync["FontScalingButton"].Add_Click({
    Write-Debug "FontScalingButton clicked"
    Invoke-WPFPopup -PopupActionTable @{ "Settings" = "Hide"; "Theme" = "Hide"; "FontScaling" = "Toggle" }
})

$sync["FontScalingSlider"].Add_ValueChanged({
    param($slider)
    $percentage = [math]::Round($slider.Value * 100)
    $sync.FontScalingValue.Text = "$percentage%"
})

$sync["FontScalingResetButton"].Add_Click({
    Write-Debug "FontScalingResetButton clicked"
    $sync.FontScalingSlider.Value = 1.0
    $sync.FontScalingValue.Text = "100%"
})

$sync["FontScalingApplyButton"].Add_Click({
    Write-Debug "FontScalingApplyButton clicked"
    $scaleFactor = $sync.FontScalingSlider.Value
    Invoke-WinUtilFontScaling -ScaleFactor $scaleFactor
    Invoke-WPFPopup -Action "Hide" -Popups @("FontScaling")
})

# Win11ISO tab button handlers
$sync["WPFTab5BT"].Add_Click({
    $sync["Form"].Dispatcher.BeginInvoke([System.Windows.Threading.DispatcherPriority]::Background, [action]{
        Invoke-WinUtilISOCheckExistingWork
    }) | Out-Null
})

$sync["WPFWin11ISOBrowseButton"].Add_Click({
    Write-Debug "WPFWin11ISOBrowseButton clicked"
    Invoke-WinUtilISOBrowse
})

$sync["WPFWin11ISODownloadLink"].Add_Click({
    Write-Debug "WPFWin11ISODownloadLink clicked"
    Start-Process "https://www.microsoft.com/software-download/windows11"
})

$sync["WPFWin11ISOMountButton"].Add_Click({
    Write-Debug "WPFWin11ISOMountButton clicked"
    Invoke-WinUtilISOMountAndVerify
})

$sync["WPFWin11ISOModifyButton"].Add_Click({
    Write-Debug "WPFWin11ISOModifyButton clicked"
    Invoke-WinUtilISOModify
})

$sync["WPFWin11ISOChooseISOButton"].Add_Click({
    Write-Debug "WPFWin11ISOChooseISOButton clicked"
    $sync["WPFWin11ISOOptionUSB"].Visibility = "Collapsed"
    Invoke-WinUtilISOExport
})

$sync["WPFWin11ISOChooseUSBButton"].Add_Click({
    Write-Debug "WPFWin11ISOChooseUSBButton clicked"
    $sync["WPFWin11ISOOptionUSB"].Visibility = "Visible"
    Invoke-WinUtilISORefreshUSBDrives
})

$sync["WPFWin11ISORefreshUSBButton"].Add_Click({
    Write-Debug "WPFWin11ISORefreshUSBButton clicked"
    Invoke-WinUtilISORefreshUSBDrives
})

$sync["WPFWin11ISOWriteUSBButton"].Add_Click({
    Write-Debug "WPFWin11ISOWriteUSBButton clicked"
    Invoke-WinUtilISOWriteUSB
})

$sync["WPFWin11ISOCleanResetButton"].Add_Click({
    Write-Debug "WPFWin11ISOCleanResetButton clicked"
    Invoke-WinUtilISOCleanAndReset
})

# RAM Tools tab buttons are handled by the shared global Button click binding above.
$sync["Form"].ShowDialog() | Out-Null
Stop-Transcript
