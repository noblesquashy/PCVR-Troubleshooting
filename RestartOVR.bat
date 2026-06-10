@echo off
setlocal enabledelayedexpansion

:: -- Require admin --------------------------------------------------------------
net session >nul 2>&1
if errorlevel 1 (
    echo ERROR: This script must be run as Administrator.
    pause
    exit /b 1
)

:: -- Find Steam install path from registry --------------------------------------
set "STEAM_EXE="
for /f "tokens=2*" %%A in ('reg query "HKLM\SOFTWARE\WOW6432Node\Valve\Steam" /v "InstallPath" 2^>nul') do set "STEAM_EXE=%%B\steam.exe"
if not defined STEAM_EXE (
    for /f "tokens=2*" %%A in ('reg query "HKCU\SOFTWARE\Valve\Steam" /v "SteamPath" 2^>nul') do set "STEAM_EXE=%%B\steam.exe"
)

:: -- Track whether Steam was running --------------------------------------------
set "STEAM_WAS_RUNNING=0"

:: -- Stop SteamVR ---------------------------------------------------------------
tasklist /fi "imagename eq vrmonitor.exe" /fo csv 2>nul | find /i "vrmonitor.exe" >nul
if not errorlevel 1 (
    echo [*] Stopping SteamVR...
    taskkill /f /im vrmonitor.exe    >nul 2>&1
    taskkill /f /im vrserver.exe     >nul 2>&1
    taskkill /f /im vrcompositor.exe >nul 2>&1
    taskkill /f /im vrdashboard.exe  >nul 2>&1
    taskkill /f /im vrwebhelper.exe  >nul 2>&1
    taskkill /f /im vrstartup.exe    >nul 2>&1
) else (
    echo [ ] SteamVR not running, skipping.
)

:: -- Stop Meta Horizon App (Link) -----------------------------------------------
:: Client.exe is generic, so match only Oculus-pathed instances.
set "META_RUNNING="
for /f %%P in ('powershell -NoProfile -Command "(Get-Process Client -ErrorAction SilentlyContinue | Where-Object { $_.Path -like '*Oculus*' }).Count"') do set "META_RUNNING=%%P"
if defined META_RUNNING if not "!META_RUNNING!"=="0" (
    echo [*] Stopping Meta Horizon App...
    powershell -NoProfile -Command "Get-Process Client -ErrorAction SilentlyContinue | Where-Object { $_.Path -like '*Oculus*' } | Stop-Process -Force"
) else (
    echo [ ] Meta Horizon App not running, skipping.
)

:: -- Stop Steam -----------------------------------------------------------------
tasklist /fi "imagename eq steam.exe" /fo csv 2>nul | find /i "steam.exe" >nul
if not errorlevel 1 (
    echo [*] Stopping Steam...
    set "STEAM_WAS_RUNNING=1"
    taskkill /f /im steam.exe >nul 2>&1
) else (
    echo [ ] Steam not running, skipping.
)

:: Give processes time to fully exit
timeout /t 3 /nobreak >nul

:: -- Restart OVRService ---------------------------------------------------------
echo [*] Stopping OVRService...
sc stop OVRService >nul 2>&1

:waitstop
sc query OVRService | find "STATE" | find "STOPPED" >nul
if errorlevel 1 (
    timeout /t 1 /nobreak >nul
    goto waitstop
)

echo [*] Starting OVRService...
sc start OVRService >nul 2>&1

:: Brief wait for service to initialize before relaunching Steam
timeout /t 3 /nobreak >nul

:: -- Restart Steam if it was running --------------------------------------------
if "!STEAM_WAS_RUNNING!"=="1" (
    if defined STEAM_EXE (
        if exist "!STEAM_EXE!" (
            echo [*] Restarting Steam...
            start "" "!STEAM_EXE!"
        ) else (
            echo [!] WARNING: Could not find Steam at: !STEAM_EXE!
        )
    ) else (
        echo [!] WARNING: Steam was running but install path could not be determined.
    )
) else (
    echo [ ] Steam was not running, skipping restart.
)

echo.
echo Done.
pause
