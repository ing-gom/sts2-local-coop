<#
  coop-embed.ps1  —  Sts2SoloCoop  (EXPERIMENTAL / spike)

  Embeds two Slay the Spire 2 instances INSIDE one container window (a WinForms host), side by side as
  a grid, using Win32 window reparenting (SetParent). The container moves/resizes as one unit; the two
  children re-fill their halves on resize.

  Auto-orders host = LEFT, client = RIGHT once they connect: the client instance renames its window to
  "Slay The Spire 2 (Client)" when it joins (fastmp), so a timer detects it and puts it on the right.

  Closing the container window QUITS BOTH game instances.

  ⚠ Reparenting a GPU game is fragile; if a panel is black / input dead / jittering, close this window
     and use coop-launch.ps1 (plain tiling) instead.

  Usage:
      ./coop-embed.ps1                 # ensure 2 instances (--fastmp), embed them side by side
      ./coop-embed.ps1 -NoLaunch       # embed two already-running instances
      ./coop-embed.ps1 -Vertical       # stack top/bottom instead of left/right
#>
param(
    [switch]$NoLaunch,
    [switch]$Vertical,
    [switch]$Windowed,   # movable bordered container (may misalign the in-game cursor); default is a
                         # borderless container pinned to screen (0,0), which keeps the cursor aligned
    [int]$Count = 2
)

$ErrorActionPreference = 'Stop'
$Exe = 'C:\Program Files (x86)\Steam\steamapps\common\Slay the Spire 2\SlayTheSpire2.exe'

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type @"
using System;
using System.Text;
using System.Runtime.InteropServices;
public static class Embedder {
    const int GWL_STYLE = -16;
    const uint WS_CHILD = 0x40000000, WS_POPUP = 0x80000000, WS_CAPTION = 0x00C00000,
               WS_THICKFRAME = 0x00040000, WS_MINIMIZEBOX = 0x00020000, WS_MAXIMIZEBOX = 0x00010000;
    [DllImport("user32.dll")] static extern int GetWindowLong(IntPtr h, int i);
    [DllImport("user32.dll")] static extern int SetWindowLong(IntPtr h, int i, int v);
    [DllImport("user32.dll")] static extern IntPtr SetParent(IntPtr c, IntPtr p);
    [DllImport("user32.dll")] static extern bool MoveWindow(IntPtr h, int x, int y, int w, int hh, bool r);
    [DllImport("user32.dll")] static extern bool ShowWindow(IntPtr h, int c);
    [DllImport("user32.dll", CharSet = CharSet.Unicode)] static extern int GetWindowText(IntPtr h, StringBuilder s, int max);
    public static int GetStyle(IntPtr h) { return GetWindowLong(h, GWL_STYLE); }
    public static string GetTitle(IntPtr h) { var sb = new StringBuilder(256); GetWindowText(h, sb, sb.Capacity); return sb.ToString(); }
    public static void Embed(IntPtr child, IntPtr parent) {
        uint s = (uint)GetWindowLong(child, GWL_STYLE);
        s = (s & ~(WS_POPUP | WS_CAPTION | WS_THICKFRAME | WS_MINIMIZEBOX | WS_MAXIMIZEBOX)) | WS_CHILD;
        SetWindowLong(child, GWL_STYLE, (int)s);
        SetParent(child, parent);
        ShowWindow(child, 5); // SW_SHOW
    }
    public static void Move(IntPtr child, int x, int y, int w, int h) { MoveWindow(child, x, y, w, h, true); }
}
"@

function Get-GameProcs { Get-Process -Name SlayTheSpire2 -ErrorAction SilentlyContinue }

# 1) Ensure two instances (unless -NoLaunch).
if (-not $NoLaunch) {
    if (-not (Test-Path $Exe)) { throw "Game exe not found: $Exe" }
    while (@(Get-GameProcs).Count -lt $Count) {
        Write-Host 'Launching a Slay the Spire 2 instance (--fastmp = local ENet multiplayer)...'
        Start-Process $Exe -ArgumentList '--fastmp'
        Start-Sleep -Seconds 6
    }
}

Write-Host "Waiting for $Count game window(s)..."
$deadline = (Get-Date).AddSeconds(120)
do {
    Start-Sleep -Seconds 2
    $procs = @(Get-GameProcs | Where-Object { $_.MainWindowHandle -ne 0 } | Select-Object -First $Count)
} while ($procs.Count -lt $Count -and (Get-Date) -lt $deadline)
if ($procs.Count -lt $Count) { throw "Only $($procs.Count) game window(s) ready." }

# Script-scoped state so the timer + event handlers can reach it.
$script:children = @()
foreach ($p in $procs) {
    $script:children += [pscustomobject]@{ Handle = $p.MainWindowHandle; Pid = $p.Id }
}

$script:vertical = [bool]$Vertical

# 2) Container window.
$form = New-Object System.Windows.Forms.Form
$form.Text = 'STS2 Co-op — embedded'
$form.BackColor = [System.Drawing.Color]::Black
$form.KeyPreview = $true
if ($Windowed) {
    # Movable, resizable container. NOTE: because the container's client area is NOT at screen (0,0),
    # the embedded games' cursor can be OFFSET (a Godot child-window quirk). Use the default mode, or
    # coop-launch.ps1 (tiling), if the cursor misaligns.
    $form.StartPosition = 'CenterScreen'
    $form.Size = New-Object System.Drawing.Size(1600, 900)
    $form.FormBorderStyle = 'Sizable'
} else {
    # Borderless container pinned to screen (0,0). Its client origin == the screen origin, so an
    # embedded child window's parent-relative coords equal screen coords — which keeps Godot's mouse
    # mapping aligned (offsetting the container is what shifts the in-game cursor). Press Esc to close.
    $b = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
    $form.FormBorderStyle = 'None'
    $form.StartPosition = 'Manual'
    $form.Location = New-Object System.Drawing.Point(0, 0)
    $form.Size = New-Object System.Drawing.Size($b.Width, $b.Height)
}
$form.Add_KeyDown({ if ($_.KeyCode -eq 'Escape') { $form.Close() } })

function Reflow {
    $w = $form.ClientSize.Width; $h = $form.ClientSize.Height
    if ($script:children.Count -lt 2) { return }
    if ($script:vertical) {
        $half = [int]($h / 2)
        [Embedder]::Move($script:children[0].Handle, 0, 0,     $w, $half)
        [Embedder]::Move($script:children[1].Handle, 0, $half, $w, $h - $half)
    } else {
        $half = [int]($w / 2)
        [Embedder]::Move($script:children[0].Handle, 0,     0, $half,      $h)
        [Embedder]::Move($script:children[1].Handle, $half, 0, $w - $half, $h)
    }
}

# Put the client ("(Client)" in title) at index 1 (right/bottom), host at index 0. Returns $true if the
# order changed. Titles only become distinguishable AFTER the client joins, so a timer re-checks.
function ReorderByRole {
    if ($script:children.Count -lt 2) { return $false }
    $isClient = @($script:children | ForEach-Object { [Embedder]::GetTitle($_.Handle) -like '*(Client)*' })
    # Want: index 0 = NOT client, index 1 = client. Only swap if exactly one is the client and it's at [0].
    if ($isClient[0] -and -not $isClient[1]) {
        $tmp = $script:children[0]; $script:children[0] = $script:children[1]; $script:children[1] = $tmp
        return $true
    }
    return $false
}

$form.Add_Shown({
    foreach ($c in $script:children) { [Embedder]::Embed($c.Handle, $form.Handle) }
    Reflow
    Write-Host 'Embedded. Host = left/top, client = right/bottom (auto-sorted once the client joins).'
    Write-Host 'Reminder: to move to the next map node, click it in BOTH panels (co-op is a shared vote).'
})
$form.Add_Resize({ if ($form.WindowState -ne 'Minimized') { Reflow } })

# Timer: keep host/client ordered correctly as the client joins (title change).
$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 1500
$timer.Add_Tick({ if (ReorderByRole) { Reflow } })
$timer.Start()

$form.Add_FormClosing({
    $timer.Stop()
    # Closing the container QUITS both games.
    foreach ($c in $script:children) {
        try { Stop-Process -Id $c.Pid -Force -ErrorAction Stop } catch {}
    }
    Write-Host 'Closed container — terminated both game instances.'
})

[void]$form.ShowDialog()
