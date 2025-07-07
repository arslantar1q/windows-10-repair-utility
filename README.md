# Windows 10 One-Click Repair Utility

A self-elevating PowerShell script that walks through a full suite of repair, cleanup, optimization, and reset steps to restore your Windows 10 installation to near–fresh-install speed, reliability, and stability—without touching or deleting any user data.

---

## Features

- **Auto-elevation** to Administrator  
- **Windows Update reset** (services & folders)  
- **Component store cleanup** (`DISM /StartComponentCleanup /ResetBase`)  
- **Offline health repair** (`DISM /RestoreHealth`)  
- **System file verification** (`SFC /scannow`)  
- **Disk error check** (schedules `CHKDSK /F /R` on next reboot)  
- **Drive optimization** (defrag + TRIM)  
- **Temporary file cleanup** (user & system temp, SoftwareDistribution\Download)  
- **Network stack reset** (Winsock & IP)  
- **Comprehensive logging** (timestamped transcript)  
- **CLI progress UI** and final reboot prompt  

---

## Prerequisites

- **Windows 10** (tested on v1607 and later)  
- **PowerShell 5.1+** (built-in on most Windows 10 systems)  
- **ExecutionPolicy** set to allow script execution (the script will auto-bypass if needed)  

---

## Installation

1. Download or copy the contents below into a file named  
   `Repair-Windows10.ps1`  
2. Place the script in any folder where you have write permission  
   (e.g. `C:\Tools\Repair-Windows10\`)  

---

## Usage

1. **Run as Administrator**  
   - Right-click the `.ps1` file → **Run with PowerShell**  
   - OR open a PowerShell window as Administrator and execute:
     ```powershell
     cd "C:\Tools\Repair-Windows10"
     .\Repair-Windows10.ps1
     ```

2. **Follow the on-screen prompts**  
   - Press **Enter** to confirm start  
   - Watch the progress bar as each repair step runs  
   - At the end, choose whether to reboot now or later  

3. **Review the log**  
   - A timestamped transcript (`WindowsRepairLog_YYYYMMDD_HHMMSS.txt`) is saved in the script folder  

---

## What It Does

1. **Auto-Elevation**  
   Ensures full admin rights by restarting itself with elevated privileges.  

2. **Windows Update Reset**  
   Stops Update services, renames `SoftwareDistribution` & `catroot2` folders (preserving old data), then restarts services.  

3. **Component Store Cleanup**  
   Runs `DISM /Online /Cleanup-Image /StartComponentCleanup /ResetBase` to reclaim space and remove superseded components.  

4. **DISM RestoreHealth**  
   Issues `DISM /Online /Cleanup-Image /RestoreHealth` to repair the component store from Windows Update.  

5. **SFC Scan**  
   Executes `sfc /scannow` to verify and restore protected system files.  

6. **Schedule CHKDSK**  
   Automatically schedules `chkdsk C: /F /R` on next reboot to fix any underlying disk errors—no user data is modified until reboot.  

7. **Optimize & TRIM**  
   Uses `Optimize-Volume` to defragment and TRIM the system volume for peak performance.  

8. **Temporary File Cleanup**  
   Deletes contents of user & system TEMP folders and Windows Update download cache; runs `CleanMgr.exe /sagerun:1` for additional built-in cleanup.  

9. **Network Reset**  
   Resets Winsock catalog and TCP/IP stack via `netsh winsock reset` and `netsh int ip reset`.  

10. **Logging & Reboot Prompt**  
    Captures all console output to a timestamped log file and prompts you to reboot when finished.  

---

## Troubleshooting

- **Script won’t run**  
  Ensure PowerShell execution policy allows script execution. You can bypass policy with:
  ```powershell
  powershell -ExecutionPolicy Bypass -File .\Repair-Windows10.ps1

- **Permission errors**
  Make sure you launched PowerShell as Administrator.

- **Long DISM/SFC times**
  These tools can take several minutes on slower hardware. Please be patient.

## License & Disclaimer
**This script is provided “as-is” without warranty. Use at your own risk. Always back up critical data before running system-level repair tools.**

## Screenshots

![40p](https://github.com/user-attachments/assets/d6d2fb41-153b-4066-b4ad-5cae7aa507dd)

