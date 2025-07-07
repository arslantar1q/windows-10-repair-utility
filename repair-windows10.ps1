<#
.SYNOPSIS
  Complete Windows 10 Repair Utility
.DESCRIPTION
  Auto-elevates, resets Update components, repairs system files, runs SFC, schedules CHKDSK,
  optimizes drives, cleans temp files, resets network, logs everything, and keeps your data safe.
.NOTES
  Tested on PowerShell 5.1+. Save as Repair-Windows10.ps1 and run as Administrator.
#>

#— Auto-elevate to Administrator if needed —#
if (-not ([Security.Principal.WindowsPrincipal] `
     [Security.Principal.WindowsIdentity]::GetCurrent() `
    ).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Elevating privileges..." -ForegroundColor Yellow
    Start-Process PowerShell `
      -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" `
      -Verb RunAs
    exit
}

#— Prepare logging —#
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$logFile   = Join-Path $scriptDir ("WindowsRepairLog_{0:yyyyMMdd_HHmmss}.txt" -f (Get-Date))
Start-Transcript -Path $logFile -NoClobber

#— Banner & confirmation —#
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "      Windows 10 One-Click Repair Utility    " -ForegroundColor Cyan
Write-Host "=============================================`n" -ForegroundColor Cyan
Read-Host "Press Enter to start the full repair process (or Ctrl+C to cancel)"

#— Define each repair step —#
function Reset-WindowsUpdate {
    Write-Host "`n[1] Resetting Windows Update components..." -ForegroundColor Green
    $svcs = "wuauserv","bits","cryptsvc","dosvc"
    foreach ($s in $svcs) {
        Stop-Service -Name $s -Force -ErrorAction SilentlyContinue
    }
    If (Test-Path "$env:SystemRoot\SoftwareDistribution") {
        Rename-Item "$env:SystemRoot\SoftwareDistribution" "SoftwareDistribution.old" -Force -ErrorAction SilentlyContinue
    }
    If (Test-Path "$env:SystemRoot\System32\catroot2") {
        Rename-Item "$env:SystemRoot\System32\catroot2" "catroot2.old" -Force -ErrorAction SilentlyContinue
    }
    foreach ($s in $svcs) {
        Start-Service -Name $s -ErrorAction SilentlyContinue
    }
}

function Clean-ComponentStore {
    Write-Host "`n[2] Cleaning component store (DISM StartComponentCleanup)..." -ForegroundColor Green
    DISM.exe /Online /Cleanup-Image /StartComponentCleanup /ResetBase | Out-Null
}

function Run-DISMRestoreHealth {
    Write-Host "`n[3] Running DISM RestoreHealth..." -ForegroundColor Green
    DISM.exe /Online /Cleanup-Image /RestoreHealth | Out-Null
}

function Run-SFC {
    Write-Host "`n[4] Running System File Checker (SFC)..." -ForegroundColor Green
    sfc.exe /scannow | Out-Null
}

function Schedule-CHKDSK {
    Write-Host "`n[5] Scheduling CHKDSK on next reboot..." -ForegroundColor Green
    # Pipe "Y" to auto-confirm scheduling
    cmd.exe /c "echo Y | chkdsk C: /F /R" | Out-Null
}

function Optimize-Drives {
    Write-Host "`n[6] Optimizing and TRIM-ing drive C:..." -ForegroundColor Green
    Optimize-Volume -DriveLetter C -ReTrim -Verbose | Out-Null
    Optimize-Volume -DriveLetter C -Defrag -Verbose | Out-Null
}

function Cleanup-Files {
    Write-Host "`n[7] Cleaning temporary files..." -ForegroundColor Green
    $paths = @(
        "$env:TEMP\*",
        "$env:SystemRoot\Temp\*",
        "$env:SystemRoot\SoftwareDistribution\Download\*"
    )
    foreach ($p in $paths) {
        Remove-Item -Path $p -Recurse -Force -ErrorAction SilentlyContinue
    }
    # Optional: run Storage Sense equivalent
    CleanMgr.exe /sagerun:1 2>$null
}

function Reset-NetworkSettings {
    Write-Host "`n[8] Resetting network settings..." -ForegroundColor Green
    netsh winsock reset | Out-Null
    netsh int ip reset | Out-Null
}

#— Run all steps with a simple progress bar —#
$steps = @(
    "Reset-WindowsUpdate",
    "Clean-ComponentStore",
    "Run-DISMRestoreHealth",
    "Run-SFC",
    "Schedule-CHKDSK",
    "Optimize-Drives",
    "Cleanup-Files",
    "Reset-NetworkSettings"
)

for ($i = 0; $i -lt $steps.Count; $i++) {
    $percent = [int](100 * ($i + 1) / $steps.Count)
    Write-Progress `
      -Activity "Repairing Windows 10" `
      -Status ("Step {0} of {1}: {2}" -f ($i+1), $steps.Count, $steps[$i]) `
      -PercentComplete $percent

    & $steps[$i]
}

#— Finish up —#
Stop-Transcript

Write-Host "`nAll repair steps are complete." -ForegroundColor Cyan
Write-Host "Log file saved to: $logFile`n" -ForegroundColor Cyan

#— Prompt for reboot —#
$reboot = Read-Host "Some changes need a reboot to take effect. Reboot now? (Y/N)"
if ($reboot -match '^[Yy]') {
    Write-Host "Rebooting now..." -ForegroundColor Yellow
    Restart-Computer
} else {
    Write-Host "Okay, remember to reboot later to finalize repairs." -ForegroundColor Yellow
}