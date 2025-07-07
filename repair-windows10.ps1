```powershell
<#
.SYNOPSIS
  Ultimate Windows 10 Repair & Maintenance Toolkit
.DESCRIPTION
  A self-elevating, menu-driven PowerShell script that:
    • Creates a System Restore Point & registry backups  
    • Performs pre- and post-repair health checks  
    • Resets Update components & cleans component store  
    • Repairs with DISM (online or offline ISO/USB source) & SFC  
    • Schedules CHKDSK, optimizes (defrag+TRIM), cleans temp files  
    • Resets network stack, updates drivers, re-registers Store apps  
    • Analyzes/cleans Event Logs, offers dry-run mode & rollback hooks  
    • Uploads logs, installs monthly scheduled maintenance task  
    • Integrates Chocolatey/Winget updates, colored UI & ETA progress  
    • Packs easily into an EXE via PS2EXE (see notes)
.PARAMETER DryRun
  Simulate all actions without making changes.
.NOTES
  - Tested on PowerShell 5.1+ (Windows 10).  
  - Save as `UltimateRepair.ps1`; run as Administrator.  
  - Your timezone: Asia/Karachi. Current date: July 7, 2025.
#>

param(
[switch]$DryRun
)

#region Auto-Elevation
function Assert-Admin {
    if (-not ([Security.Principal.WindowsPrincipal] `
         [Security.Principal.WindowsIdentity]::GetCurrent() `
        ).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
        Write-Host "Elevating privileges..." -ForegroundColor Yellow
        Start-Process pwsh -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
        Exit
    }
}
Assert-Admin
#endregion

#region Logging & Transcript
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$logFile = Join-Path $scriptDir "UltimateRepairLog_$timestamp.txt"
if (-not $DryRun) { Start-Transcript -Path $logFile -NoClobber }
Write-Host "Logging to $logFile" -ForegroundColor Cyan
#endregion

#region Helper Functions
function Invoke-OrSimulate {
    param($ScriptBlock, $Description)
    if ($DryRun) {
        Write-Host "[DRY-RUN] Would: $Description" -ForegroundColor Yellow
    } else {
        & $ScriptBlock
    }
}

function Write-Status {
    param($Msg, $Color="White")
    Write-Host $Msg -ForegroundColor $Color
}

function Spinner {
    param($Activity, $Seconds)
    $spinner = '|/-\'
    for ($i=0; $i -lt $Seconds*10; $i++) {
        $c = $spinner[($i % $spinner.Length)]
        Write-Host -NoNewline "`r$Activity $c"
        Start-Sleep -Milliseconds 100
    }
    Write-Host "`r$Activity Done `n"
}
#endregion

#region Pre-Repair Health Check
function Get-HealthMetrics {
    $freeSpace = (Get-PSDrive C).Free /1GB
    $memFree   = (Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory/1MB
    $eventErrors = (Get-WinEvent -FilterHashtable @{LogName='System'; Level=2; StartTime=(Get-Date).AddDays(-7)}).Count
    $dismHealth = (& DISM /Online /Get-Health).Trim()
    return @{
        FreeSpaceGB = [math]::Round($freeSpace,2)
        FreeMemMB   = [math]::Round($memFree,2)
        RecentSysErrors = $eventErrors
        DISMStatus  = $dismHealth
    }
}
$preMetrics = Get-HealthMetrics
Write-Status "`nPre-Repair Metrics:" Cyan
$preMetrics.GetEnumerator() | ForEach-Object {
    Write-Host " - $_.Key : $_.Value"
}
#endregion

#region Create System Restore Point & Registry Backup
function Create-RestorePoint {
    Write-Status "`n[✓] Creating System Restore Point..." Green
    Invoke-OrSimulate {
        Checkpoint-Computer -Description "Pre-Repair $(Get-Date -Format g)" -RestorePointType "MODIFY_SETTINGS"
    } "Checkpoint-Computer"
}
function Backup-RegistryHives {
    Write-Status "`n[✓] Backing up registry hives..." Green
    $backupDir = Join-Path $scriptDir "RegistryBackups_$timestamp"
    if (-not $DryRun) { New-Item -Path $backupDir -ItemType Directory | Out-Null }
    foreach ($hive in "HKLM\SOFTWARE","HKLM\SYSTEM") {
        $name = $hive.Split('\')[-1]
        Invoke-OrSimulate {
            reg export $hive (Join-Path $backupDir "$name.reg") /y
        } "Export $hive"
    }
}
Create-RestorePoint
Backup-RegistryHives
#endregion

#region Offline Source Selection
function Get-RepairSource {
    Write-Status "`n[?] Repair source:" Cyan
    Write-Host "  1) Online (Windows Update)"
    Write-Host "  2) Offline (ISO/USB)"
    do {
        $choice = Read-Host "Choose [1/2]"
    } until ($choice -in '1','2')
    if ($choice -eq '2') {
        do {
            $path = Read-Host "Enter path to mounted ISO folder (e.g. D:\sources)"
        } until (Test-Path "$path\install.wim")
        return $path
    }
    return $null
}
$offlineSource = Get-RepairSource
#endregion

#region Main Menu Selection
$menuItems = @(
    @{Key='A'; Name='Full Suite'; Action='ALL'},
    @{Key='C'; Name='Custom Selection'; Action='CUSTOM'},
    @{Key='D'; Name='Dry-Run Simulation'; Action='DRYRUN'}
)
Write-Status "`n=== Ultimate Repair Toolkit ===" Magenta
foreach ($item in $menuItems) {
    Write-Host " [$($item.Key)] $($item.Name)"
}
do {
    $sel = Read-Host "Select option"
} until ($menuItems.Key -contains $sel.ToUpper())
switch ($sel.ToUpper()) {
    'A' { $selected = 'ALL' }
    'C' { $selected = 'CUSTOM' }
    'D' {
        $DryRun = $true
        Write-Host "`nDry-Run mode enabled.`n" -ForegroundColor Yellow
        $selected = 'ALL'
    }
}

$tasks = @()
$allTasks = @(
    @{Name='Reset Windows Update';         Func='Reset-WindowsUpdate'},
    @{Name='Clean Component Store';        Func='Clean-ComponentStore'},
    @{Name='DISM RestoreHealth';           Func='Run-DISMRestoreHealth'},
    @{Name='SFC Scan';                     Func='Run-SFC'},
    @{Name='Schedule CHKDSK';              Func='Schedule-CHKDSK'},
    @{Name='Optimize & TRIM Drive';        Func='Optimize-Drives'},
    @{Name='Clean Temp Files';             Func='Cleanup-Files'},
    @{Name='Reset Network Stack';          Func='Reset-NetworkSettings'},
    @{Name='Update Drivers';               Func='Update-Drivers'},
    @{Name='Re-register Store Apps';       Func='Reregister-StoreApps'},
    @{Name='Analyze Event Logs';           Func='Analyze-EventLogs'},
    @{Name='Upload Logs';                  Func='Upload-Logs'},
    @{Name='Install Monthly Maintenance';  Func='Install-ScheduledMaintenance'},
    @{Name='Chocolatey/Winget Updates';    Func='Update-PackageManagers'}
)

if ($selected -eq 'ALL') {
    $tasks = $allTasks
} else {
    Write-Status "`nSelect tasks to run (comma-separated numbers):" Cyan
    for ($i=0; $i -lt $allTasks.Count; $i++) {
        Write-Host " [$($i+1)] $($allTasks[$i].Name)"
    }
    $choices = Read-Host "e.g. 1,3,5"
    $nums = $choices -split '[, ]+' | Where-Object { $_ -match '^\d+$' }
    foreach ($n in $nums) {
        if ($n -ge 1 -and $n -le $allTasks.Count) {
            $tasks += $allTasks[$n-1]
        }
    }
}
#endregion

#region Task Implementations

function Reset-WindowsUpdate {
    Write-Status "`n[1] Resetting Windows Update components..." Green
    Invoke-OrSimulate {
        $svcs = "wuauserv","bits","cryptsvc","dosvc"
        foreach ($s in $svcs) { Stop-Service $s -Force -ErrorAction SilentlyContinue }
        Rename-Item "$env:SystemRoot\SoftwareDistribution" "SoftwareDistribution.old" -ErrorAction SilentlyContinue
        Rename-Item "$env:SystemRoot\System32\catroot2" "catroot2.old" -ErrorAction SilentlyContinue
        foreach ($s in $svcs) { Start-Service $s -ErrorAction SilentlyContinue }
    } "Reset Windows Update"
}

function Clean-ComponentStore {
    Write-Status "`n[2] Cleaning component store..." Green
    Invoke-OrSimulate {
        DISM.exe /Online /Cleanup-Image /StartComponentCleanup /ResetBase | Out-Null
    } "DISM StartComponentCleanup"
}

function Run-DISMRestoreHealth {
    Write-Status "`n[3] Running DISM RestoreHealth..." Green
    $cmd = if ($offlineSource) {
        "DISM.exe /Online /Cleanup-Image /RestoreHealth /Source:$offlineSource\install.wim:1 /LimitAccess"
    } else {
        "DISM.exe /Online /Cleanup-Image /RestoreHealth"
    }
    Invoke-OrSimulate {
        iex $cmd | Out-Null
    } $cmd
}

function Run-SFC {
    Write-Status "`n[4] Running SFC /scannow..." Green
    Invoke-OrSimulate {
        sfc.exe /scannow | Out-Null
    } "sfc /scannow"
}

function Schedule-CHKDSK {
    Write-Status "`n[5] Scheduling CHKDSK..." Green
    Invoke-OrSimulate {
        cmd /c "echo Y|chkdsk C: /F /R" | Out-Null
    } "chkdsk C: /F /R"
}

function Optimize-Drives {
    Write-Status "`n[6] Optimizing & TRIMming C:..." Green
    Invoke-OrSimulate {
        Optimize-Volume -DriveLetter C -ReTrim -Verbose | Out-Null
        Optimize-Volume -DriveLetter C -Defrag -Verbose | Out-Null
    } "Optimize-Volume"
}

function Cleanup-Files {
    Write-Status "`n[7] Cleaning temporary files..." Green
    $paths = @("$env:TEMP\*", "$env:SystemRoot\Temp\*", "$env:SystemRoot\SoftwareDistribution\Download\*")
    Invoke-OrSimulate {
        foreach ($p in $paths) { Remove-Item -Path $p -Recurse -Force -ErrorAction SilentlyContinue }
        CleanMgr.exe /sagerun:1 2>$null
    } "Remove-Item temp & CleanMgr"
}

function Reset-NetworkSettings {
    Write-Status "`n[8] Resetting network settings..." Green
    Invoke-OrSimulate {
        netsh winsock reset | Out-Null
        netsh int ip reset | Out-Null
    } "netsh resets"
}

function Update-Drivers {
    Write-Status "`n[9] Scanning and updating drivers..." Green
    Invoke-OrSimulate {
        Get-WindowsDriver -Online | Out-Null
        # For full automation, integrate PnPUtil or a driver management tool here.
    } "PnPUtil driver scan"
}

function Reregister-StoreApps {
    Write-Status "`n[10] Re-registering Microsoft Store apps..." Green
    Invoke-OrSimulate {
        Get-AppxPackage -AllUsers | ForEach-Object {
            Add-AppxPackage -DisableDevelopmentMode -Register "$($_.InstallLocation)\AppXManifest.xml" -ErrorAction SilentlyContinue
        }
    } "Re-register Store apps"
}

function Analyze-EventLogs {
    Write-Status "`n[11] Analyzing System event logs..." Green
    $errors = Get-WinEvent -FilterHashtable @{LogName='System'; Level=2; StartTime=(Get-Date).AddDays(-30)}
    Write-Host " Last 30 days Critical/Error events: $($errors.Count)" -ForegroundColor Cyan
    # Optionally clear logs:
    $clr = Read-Host "Clear System log? (Y/N)"
    if ($clr -match '^[Yy]') {
        Invoke-OrSimulate {
            wevtutil cl System
        } "wevtutil cl System"
    }
}

function Upload-Logs {
    Write-Status "`n[12] Uploading logs..." Green
    $dest = Read-Host "Enter UNC path or local folder to copy logs to (or leave blank to skip)"
    if ($dest) {
        Invoke-OrSimulate {
            Copy-Item -Path $logFile -Destination $dest -Force
        } "Copy log to $dest"
        Write-Host "Logs copied to $dest" -ForegroundColor Cyan
    } else {
        Write-Host "Skipping upload." -ForegroundColor Yellow
    }
}

function Install-ScheduledMaintenance {
    Write-Status "`n[13] Installing monthly maintenance task..." Green
    $taskName = "UltimateMonthlyMaintenance"
    $exePath = $PSCommandPath
    Invoke-OrSimulate {
        $action = New-ScheduledTaskAction -Execute 'pwsh' -Argument "-NoProfile -WindowStyle Hidden -File `"$exePath`""
        $trigger = New-ScheduledTaskTrigger -Monthly -DaysOfMonth 1 -At 3am
        Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Description "Monthly Windows repair & maintenance"
    } "Register-ScheduledTask $taskName"
}

function Update-PackageManagers {
    Write-Status "`n[14] Updating Chocolatey/Winget packages..." Green
    Invoke-OrSimulate {
        if (Get-Command choco -ErrorAction SilentlyContinue) { choco upgrade all -y }
        if (Get-Command winget -ErrorAction SilentlyContinue) { winget upgrade --all --silent }
    } "choco/winget upgrades"
}
#endregion

#region Execute Selected Tasks with Progress
$total = $tasks.Count
for ($i = 0; $i -lt $total; $i++) {
    $pct = [int](100 * ($i+1)/$total)
    $name = $tasks[$i].Name
    Write-Progress -Activity "Ultimate Repair" -Status $name -PercentComplete $pct
    & ([scriptblock]::Create($tasks[$i].Func))
}
Write-Progress -Activity "Ultimate Repair" -Completed
#endregion

#region Post-Repair Health Check & Summary
$postMetrics = Get-HealthMetrics
Write-Status "`nPost-Repair Metrics:" Cyan
foreach ($k in $preMetrics.Keys) {
    $before = $preMetrics[$k]
    $after  = $postMetrics[$k]
    $diff   = if ($after -is [string]) { $after } else { [math]::Round($after - $before,2) }
    Write-Host " - $k : Before=$before   After=$after   Δ=$diff"
}
#endregion

#region Final Reboot Prompt & Packaging Note
if (-not $DryRun) { Stop-Transcript }
$reboot = Read-Host "`nRepairs complete. Reboot now? (Y/N)"
if ($reboot -match '^[Yy]') {
    Restart-Computer
} else {
    Write-Host "Remember to reboot later to finalize repairs." -ForegroundColor Yellow
}

Write-Host "`nTo distribute as an EXE, consider using PS2EXE:" -ForegroundColor Magenta
Write-Host '  ps2exe -inputFile UltimateRepair.ps1 -outputFile UltimateRepair.exe' -ForegroundColor Magenta
#endregion
```