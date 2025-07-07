# Ultimate Windows 10 Repair & Maintenance Toolkit

A self-elevating, menu-driven PowerShell script that restores Windows 10 to near–fresh-install performance and reliability while preserving all user data. Packed with diagnostics, backups, repair routines, cleanup tasks, and optional automation.

---

## Features

- **Auto-Elevation**  
  Detects and relaunches as Administrator if needed.
- **Dry-Run Mode**  
  Simulate every step without making changes.
- **Pre- & Post-Repair Health Checks**  
  • Free disk & memory  
  • Recent Event Log errors  
  • DISM component store health
- **System Restore Point & Registry Backup**  
  Creates a rollback point and exports SYSTEM & SOFTWARE hives.
- **Offline/Online DISM Source**  
  Detects internet status or lets you point to a mounted ISO/USB.
- **Menu-Driven Task Selection**  
  • Full-suite “one-click” run  
  • Custom selection of any combination of 14 modules
- **Windows Update Reset**  
  Stops services, renames SoftwareDistribution & Catroot2, restarts services.
- **Component Store Cleanup**  
  `DISM /StartComponentCleanup /ResetBase`
- **DISM RestoreHealth**  
  Online or `install.wim` source.
- **SFC /Scannow**  
  Verifies and repairs protected system files.
- **CHKDSK Scheduling**  
  Schedules `chkdsk C: /F /R` on next reboot.
- **Drive Optimization & TRIM**  
  Defragmentation + SSD TRIM.
- **Temp-File Cleanup**  
  User & system temp, Windows Update download cache, Disk Cleanup pass.
- **Network Stack Reset**  
  `netsh winsock reset` & `netsh int ip reset`
- **Driver Scan/Update Stub**  
  Placeholder for PnPUtil or third-party driver management.
- **Store App Re-registration**  
  Refreshes built-in Microsoft Store apps.
- **Event Log Analysis & Cleanup**  
  Counts recent errors and optionally clears the System log.
- **Log Upload**  
  Copy transcript to a UNC share or local folder.
- **Monthly Scheduled Maintenance**  
  Installs itself as a Scheduled Task to run on the 1st of every month at 3 AM.
- **Chocolatey/Winget Integration**  
  Upgrades all installed packages.
- **Colored CLI UI & ETA Spinner**  
  Color-coded statuses and spinner for long operations.
- **Rollback Hooks & Dry-Run Simulation**  
  Cleanly simulate or roll back individual steps.
- **PS2EXE Packaging Note**  
  Guidance to bundle as a standalone `.exe`.

---

## Prerequisites

- **Windows 10** (build 1607 or later)
- **PowerShell 5.1+** (built-in)
- **ExecutionPolicy** allows script execution (the script auto-bypasses if needed)
- **Administrator** privileges

---

## Installation

1. **Download** or copy the script into `UltimateRepair.ps1`.
2. **Place** it in a folder where you have write permissions (e.g. `C:\Tools\UltimateRepair\`).

---

## Usage

1. **Run As Administrator**
    - Right-click `UltimateRepair.ps1` → **Run with PowerShell**
    - OR launch PowerShell as Administrator and:
      ```powershell
      cd "C:\Tools\UltimateRepair"
      .\UltimateRepair.ps1
      ```
2. **Choose Mode**
    - **Full Suite**: run every module
    - **Custom Selection**: pick specific tasks by number
    - **Dry-Run**: preview all actions without changes
3. **Follow Prompts**
    - Select offline or online repair source
    - Confirm pre-repair restore point & registry backup
    - (If custom) choose desired modules
    - Supply any paths (e.g. log upload destination) when prompted
4. **Monitor Progress**
    - Colorful status messages and spinner for long-running steps
    - Progress bar percent complete
5. **Review Summary**
    - Pre- vs. post-repair health metrics with deltas
    - Log file saved as `UltimateRepairLog_YYYYMMDD_HHMMSS.txt` in script folder
6. **Reboot Prompt**
    - Choose to reboot immediately or later

---

## Parameters

- `-DryRun`  
  Simulates all actions. No changes are made; helpful for testing or audit.

---

## Customization & Packaging

- **PS2EXE**
  ```powershell
  ps2exe -inputFile UltimateRepair.ps1 -outputFile UltimateRepair.exe

---

---

---
Ultimate Windows 10 Repair & Maintenance Toolkit

A self-elevating, menu-driven PowerShell script that restores Windows 10 to near–fresh-install performance and reliability while preserving all user data. Packed with diagnostics, backups, repair routines, cleanup tasks, and optional automation.

Features
--------
- Auto-Elevation: Detects and relaunches as Administrator if needed.
- Dry-Run Mode: Simulate every step without making changes.
- Pre- & Post-Repair Health Checks:
  • Free disk & memory
  • Recent Event Log errors
  • DISM component store health
- System Restore Point & Registry Backup: Creates a rollback point and exports SYSTEM & SOFTWARE hives.
- Offline/Online DISM Source: Detects internet status or lets you point to a mounted ISO/USB.
- Menu-Driven Task Selection:
  • Full-suite “one-click” run
  • Custom selection of any combination of 14 modules
- Windows Update Reset: Stops services, renames SoftwareDistribution & Catroot2, restarts services.
- Component Store Cleanup: DISM /StartComponentCleanup /ResetBase
- DISM RestoreHealth: Online or install.wim source.
- SFC /Scannow: Verifies and repairs protected system files.
- CHKDSK Scheduling: Schedules chkdsk C: /F /R on next reboot.
- Drive Optimization & TRIM: Defragmentation + SSD TRIM.
- Temp-File Cleanup: User & system temp, Windows Update download cache, Disk Cleanup pass.
- Network Stack Reset: netsh winsock reset & netsh int ip reset
- Driver Scan/Update Stub: Placeholder for PnPUtil or third-party driver management.
- Store App Re-registration: Refreshes built-in Microsoft Store apps.
- Event Log Analysis & Cleanup: Counts recent errors and optionally clears the System log.
- Log Upload: Copy transcript to a UNC share or local folder.
- Monthly Scheduled Maintenance: Installs itself as a Scheduled Task to run on the 1st of every month at 3 AM.
- Chocolatey/Winget Integration: Upgrades all installed packages.
- Colored CLI UI & ETA Spinner: Color-coded statuses and spinner for long operations.
- Rollback Hooks & Dry-Run Simulation: Cleanly simulate or roll back individual steps.
- PS2EXE Packaging Note: Guidance to bundle as a standalone .exe.

Prerequisites
-------------
- Windows 10 (build 1607 or later)
- PowerShell 5.1+ (built-in)
- ExecutionPolicy allows script execution (the script auto-bypasses if needed)
- Administrator privileges

Installation
------------
1. Download or copy the script into `UltimateRepair.ps1`.
2. Place it in a folder where you have write permissions (e.g. C:\Tools\UltimateRepair\).

Usage
-----
1. Run As Administrator:
    - Right-click `UltimateRepair.ps1` → Run with PowerShell
    - OR launch PowerShell as Administrator and:
      cd "C:\Tools\UltimateRepair"
      .\UltimateRepair.ps1
2. Choose Mode:
    - Full Suite: run every module
    - Custom Selection: pick specific tasks by number
    - Dry-Run: preview all actions without changes
3. Follow Prompts:
    - Select offline or online repair source
    - Confirm pre-repair restore point & registry backup
    - (If custom) choose desired modules
    - Supply any paths (e.g. log upload destination) when prompted
4. Monitor Progress:
    - Colorful status messages and spinner for long-running steps
    - Progress bar percent complete
5. Review Summary:
    - Pre- vs. post-repair health metrics with deltas
    - Log file saved as UltimateRepairLog_YYYYMMDD_HHMMSS.txt in script folder
6. Reboot Prompt:
    - Choose to reboot immediately or later

Parameters
----------
- -DryRun: Simulates all actions. No changes are made; helpful for testing or audit.

Customization & Packaging
-------------------------
- PS2EXE:
  ps2exe -inputFile UltimateRepair.ps1 -outputFile UltimateRepair.exe
- Extend Driver Updates: Integrate PnPUtil commands or third-party driver management modules.
- Modify Scheduled Task: Adjust the trigger by editing the Install-ScheduledMaintenance function.

Troubleshooting
---------------
- Execution Policy Errors:
  Run with -ExecutionPolicy Bypass, or configure via:
  Set-ExecutionPolicy RemoteSigned -Scope LocalMachine
- Permission Denied:
  Ensure you launched PowerShell as Administrator.
- Long Repair Times:
  DISM and SFC can take 10–30 minutes on slower hardware—please be patient.

License & Disclaimer
--------------------
This script is provided “as-is” without warranty. Use at your own risk. Always back up important data before running system-level repairs.
