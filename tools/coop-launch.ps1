<#
  coop-launch.ps1  —  Sts2SoloCoop local two-instance co-op helper.

  Launches up to two Slay the Spire 2 instances and places them side by side so ONE operator can play
  both co-op characters: left = player 1, right = player 2. Switch which character you control by
  clicking a window / Alt-Tab (or use coop-control.ahk for one-key F1/F2 switching).

  Because these stay as normal TOP-LEVEL windows (unlike coop-embed.ps1, which reparents them into one
  container and can offset the in-game cursor), the cursor stays correctly aligned.

  Modes:
    ./coop-launch.ps1                 # tile across the whole screen (bordered windows)
    ./coop-launch.ps1 -Windowed       # borderless, edge-to-edge in a centered box → looks like one
                                      #   window, but WINDOWED with a correct cursor (recommended)
    ./coop-launch.ps1 -Windowed -Width 1920 -Height 1080
    ./coop-launch.ps1 -NoLaunch       # just (re)place instances that are already open
#>
param(
    [switch]$NoLaunch,
    [switch]$Windowed,
    [int]$Width  = 1600,
    [int]$Height = 900,
    [int]$Count  = 2
)

$ErrorActionPreference = 'Stop'
$Exe = 'C:\Program Files (x86)\Steam\steamapps\common\Slay the Spire 2\SlayTheSpire2.exe'

Add-Type -AssemblyName System.Windows.Forms
Add-Type @"
using System;
using System.Runtime.InteropServices;
public static class Win {
    const int GWL_STYLE = -16;
    const uint WS_CAPTION = 0x00C00000, WS_THICKFRAME = 0x00040000, WS_MINIMIZEBOX = 0x00020000,
               WS_MAXIMIZEBOX = 0x00010000, WS_BORDER = 0x00800000, WS_DLGFRAME = 0x00400000;
    const uint SWP_FRAMECHANGED = 0x0020, SWP_SHOWWINDOW = 0x0040, SWP_NOZORDER = 0x0004;
    [DllImport("user32.dll")] static extern int GetWindowLong(IntPtr h, int i);
    [DllImport("user32.dll")] static extern int SetWindowLong(IntPtr h, int i, int v);
    [DllImport("user32.dll")] static extern bool SetWindowPos(IntPtr h, IntPtr a, int x, int y, int cx, int cy, uint f);
    [DllImport("user32.dll")] static extern bool ShowWindow(IntPtr h, int c);
    public static void Borderless(IntPtr h) {
        uint s = (uint)GetWindowLong(h, GWL_STYLE);
        s &= ~(WS_CAPTION | WS_THICKFRAME | WS_MINIMIZEBOX | WS_MAXIMIZEBOX | WS_BORDER | WS_DLGFRAME);
        SetWindowLong(h, GWL_STYLE, (int)s);
    }
    public static void Place(IntPtr h, int x, int y, int w, int hh) {
        ShowWindow(h, 9); // SW_RESTORE
        SetWindowPos(h, IntPtr.Zero, x, y, w, hh, SWP_NOZORDER | SWP_FRAMECHANGED | SWP_SHOWWINDOW);
    }
}
"@

function Get-GameProcs { Get-Process -Name SlayTheSpire2 -ErrorAction SilentlyContinue }

# 1) Launch until we have $Count instances (unless -NoLaunch).
if (-not $NoLaunch) {
    if (-not (Test-Path $Exe)) { throw "Game exe not found: $Exe" }
    while (@(Get-GameProcs).Count -lt $Count) {
        Write-Host 'Launching a Slay the Spire 2 instance (--fastmp = local ENet multiplayer)...'
        Start-Process $Exe -ArgumentList '--fastmp'
        Start-Sleep -Seconds 6
    }
}

# 2) Wait for the windows.
Write-Host "Waiting for $Count game window(s)..."
$deadline = (Get-Date).AddSeconds(120)
do {
    Start-Sleep -Seconds 2
    $procs = @(Get-GameProcs | Where-Object { $_.MainWindowHandle -ne 0 } | Select-Object -First $Count)
} while ($procs.Count -lt $Count -and (Get-Date) -lt $deadline)
if ($procs.Count -eq 0) { throw 'No game windows found.' }
if ($procs.Count -lt $Count) { Write-Warning "Only $($procs.Count) window(s) ready; placing those." }

# 3) Compute the region.
$wa = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea
if ($Windowed) {
    # A centered box; borderless + edge-to-edge → looks like one window, but each game stays a normal
    # top-level window (cursor correct). Move/close each with the game's own controls or Alt-Tab.
    $rw = [Math]::Min($Width,  $wa.Width)
    $rh = [Math]::Min($Height, $wa.Height)
    $rx = $wa.X + [int](($wa.Width  - $rw) / 2)
    $ry = $wa.Y + [int](($wa.Height - $rh) / 2)
} else {
    $rw = $wa.Width; $rh = $wa.Height; $rx = $wa.X; $ry = $wa.Y
}
$halfW = [int]($rw / 2)

$i = 0
foreach ($p in ($procs | Select-Object -First $Count)) {
    if ($Windowed) { [Win]::Borderless($p.MainWindowHandle) }
    $x = $rx + ($i * $halfW)
    $w = if ($i -eq 0) { $halfW } else { $rw - $halfW }
    [Win]::Place($p.MainWindowHandle, $x, $ry, $w, $rh)
    $side = if ($i -eq 0) { 'LEFT (player 1)' } else { 'RIGHT (player 2)' }
    Write-Host "Placed PID $($p.Id) -> $side"
    $i++
}
Write-Host ''
Write-Host 'Done. Click a window (or Alt-Tab) to control that character.'
if ($Windowed) { Write-Host 'Windowed mode: borderless side-by-side. Set the game to Windowed (Settings > Video).' }
else { Write-Host 'If the windows did not resize, set the game to WINDOWED mode and re-run with -NoLaunch.' }
