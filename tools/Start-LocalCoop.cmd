@echo off
REM STS2 Local Co-op — launch two instances embedded in one window (double-click me).
REM Edit the target below to coop-launch.ps1 if you prefer desktop tiling instead of embedding.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0coop-embed.ps1"
