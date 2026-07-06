<#
  coop-launch.ps1  —  Sts2SoloCoop local two-instance co-op helper.

  Launches up to two Slay the Spire 2 instances and tiles them side by side so ONE operator can play
  both co-op characters: left window = player 1, right window = player 2. Switch which character you
  control by clicking a window or Alt-Tab (or use coop-control.ahk for one-key F1/F2 switching).

  The two real instances are genuine network peers, so all of STS2's co-op synchronizers are satisfied
  and the game behaves exactly as intended — this tool only handles launching + window layout.

  Usage (PowerShell):
      ./coop-launch.ps1              # ensure 2 instances are running, then tile them
      ./coop-launch.ps1 -NoLaunch    # just tile whatever instances are already open
      ./coop-launch.ps1 -Count 2     # target instance count (default 2)

  Notes:
   - Set the game to WINDOWED mode (not exclusive fullscreen) or tiling won't take — borderless/
     fullscreen windows ignore SetWindowPos.
   - The 2nd instance is launched directly from the exe (bypassing Steam's single-instance lock);
     keep Steam running so Steamworks initializes. Connect the two via the in-game `multiplayer test`
     console (Host on one, Join 127.0.0.1 on the other).
#>
param(
    [switch]$NoLaunch,
    [int]$Count = 2
)

$ErrorActionPreference = 'Stop'
$Exe = 'C:\Program Files (x86)\Steam\steamapps\common\Slay the Spire 2\SlayTheSpire2.exe'

Add-Type -AssemblyName System.Windows.Forms
Add-Type @"
using System;
using System.Runtime.InteropServices;
public static class Win {
    [DllImport("user32.dll")] public static extern bool SetWindowPos(IntPtr h, IntPtr after, int x, int y, int cx, int cy, uint flags);
    [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int cmd);
}
"@

function Get-GameProcs { Get-Process -Name SlayTheSpire2 -ErrorAction SilentlyContinue }

# 1) Launch until we have $Count instances (unless -NoLaunch).
if (-not $NoLaunch) {
    if (-not (Test-Path $Exe)) { throw "Game exe not found: $Exe" }
    while (@(Get-GameProcs).Count -lt $Count) {
        Write-Host 'Launching a Slay the Spire 2 instance (--fastmp = local ENet multiplayer)...'
        # --fastmp makes the NORMAL multiplayer menu use ENet localhost: Host hosts on 127.0.0.1:33771
        # and the Join screen shows a "join 127.0.0.1" button. No console / debug screen needed. Both
        # instances must be launched WITH this arg (i.e. via this script, not Steam) for it to apply.
        Start-Process $Exe -ArgumentList '--fastmp'
        Start-Sleep -Seconds 6
    }
}

# 2) Wait for the windows to exist.
Write-Host "Waiting for $Count game window(s)..."
$deadline = (Get-Date).AddSeconds(120)
do {
    Start-Sleep -Seconds 2
    $procs = @(Get-GameProcs | Where-Object { $_.MainWindowHandle -ne 0 })
} while ($procs.Count -lt $Count -and (Get-Date) -lt $deadline)

if ($procs.Count -eq 0) { throw 'No game windows found.' }
if ($procs.Count -lt $Count) { Write-Warning "Only $($procs.Count) window(s) ready; tiling those." }

# 3) Tile side by side across the primary screen's working area.
$wa = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea
$halfW = [int]($wa.Width / 2)
$SW_RESTORE = 9
$SWP_SHOWWINDOW = 0x0040
$i = 0
foreach ($p in ($procs | Select-Object -First $Count)) {
    [Win]::ShowWindow($p.MainWindowHandle, $SW_RESTORE) | Out-Null
    $x = $wa.X + ($i * $halfW)
    [Win]::SetWindowPos($p.MainWindowHandle, [IntPtr]::Zero, $x, $wa.Y, $halfW, $wa.Height, $SWP_SHOWWINDOW) | Out-Null
    $side = if ($i -eq 0) { 'LEFT (player 1)' } else { 'RIGHT (player 2)' }
    Write-Host "Tiled PID $($p.Id) -> $side"
    $i++
}
Write-Host ''
Write-Host 'Done. Click a window (or Alt-Tab) to control that character.'
Write-Host 'If the windows did not resize, set the game to WINDOWED mode and re-run with -NoLaunch.'
