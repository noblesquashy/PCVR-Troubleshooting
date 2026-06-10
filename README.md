# RestartOVR

A Windows batch script that cleanly restarts the Oculus/Meta VR runtime service (`OVRService`) and gets your VR software back to a known good state. Originally a one-line troubleshooting step, now a more robust "kick everything VR-related and bring Steam back" tool.

**NOTE:** If you are not familiar with reading and using .BAT or .PS1 files, you should never trust a script someone gives you without evaluation. Running .BATs or .PS1s as Admin are incredibly permissive and can cause damage if malicious. Be careful! 

## What it does

When run, the script:

1. **Checks for admin rights** — exits early if not elevated (the service commands require it).
2. **Looks up your Steam install path** from the registry (so it works regardless of where Steam is installed).
3. **Stops SteamVR** if it's running (`vrmonitor.exe` and related processes).
4. **Stops the Meta Horizon App / Link client** if it's running (Oculus-pathed `Client.exe` only).
5. **Stops Steam** if it's running, and remembers that it was.
6. **Restarts `OVRService`** — stops it, waits for a confirmed full shutdown, then starts it again.
7. **Restarts Steam** — but only if it was running when the script started.

SteamVR and the Meta Horizon App are intentionally **not** relaunched — only Steam is.

## Requirements

- Windows 10 or 11
- Must be run **as Administrator**
- PowerShell (ships built-in with Windows — used for reliable Meta process detection)

## Usage

Right-click `RestartOVR.bat` and select **Run as administrator**.

The script logs each step to the console and pauses at the end so you can read the output before it closes.

## Notes

- **Admin required:** The `sc stop` / `sc start` commands that restart `OVRService` will silently fail without elevation, which is why the script refuses to run unelevated.
- **Steam relaunch is conditional:** "Restart" implies Steam was open, so the script only relaunches it if it was running when started. SteamVR and Horizon stay closed.
- **Meta detection is path-filtered:** The Horizon Link client runs as `Client.exe`, which is a generic name shared by other apps. The script only targets `Client.exe` instances whose executable lives under an Oculus path, so it won't kill unrelated processes.
- **VR services are safe to force-restart:** They're effectively stateless and built to come back up. The script deliberately does **not** try to auto-detect and kill the running game, since there's no reliable way to identify "the game" and force-killing one risks corrupting saves.

## Troubleshooting

- **"This script must be run as Administrator"** — right-click and choose *Run as administrator*.
- **Steam doesn't relaunch** — the registry lookup may have failed; the script will print the path it tried. Confirm Steam is installed and the path exists.
- **SteamVR/Meta "not running, skipping" when they are running** — process names can change between client versions. Check Task Manager's *Details* tab for the actual process name and update the relevant block.
