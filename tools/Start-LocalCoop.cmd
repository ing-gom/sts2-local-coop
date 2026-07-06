@echo off
REM STS2 Local Co-op — launch two instances side by side (double-click me).
REM Windowed borderless (correct cursor). For fullscreen-embedded-in-one-window use coop-embed.ps1;
REM for full-screen desktop tiling drop the -Windowed flag.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0coop-launch.ps1" -Windowed
