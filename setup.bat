@echo off
setlocal enabledelayedexpansion

REM =====================================================================
REM  setup.bat  --  One-time setup for WinDBG Hacker
REM
REM  Run this ONCE after cloning the repo. It:
REM    1. Applies the Matrix Hacker color theme (registry import)
REM    2. Creates a Desktop shortcut to hacker.bat
REM    3. Optionally pre-downloads symbols for offline use
REM
REM  After setup: just double-click the Desktop shortcut (or hacker.bat)
REM  to launch WinDBG with the full hacker environment.
REM =====================================================================

title H4CK3R :: Setup

for /f %%a in ('echo prompt $E^| cmd') do set "ESC=%%a"
set "GRN=!ESC![38;2;0;184;0m"
set "BRT=!ESC![38;2;0;224;0m"
set "CYN=!ESC![38;2;0;204;204m"
set "YLW=!ESC![38;2;255;204;0m"
set "RED=!ESC![38;2;255;51;51m"
set "DIM=!ESC![38;2;0;80;0m"
set "RST=!ESC![0m"

cls
echo !GRN!
echo  =========================================================================
echo    __  __     _     __  _  _  ____  ____     __    __  __ ____   ____
echo   ^|  \/  ^|   / \   ^|__^^|  \^| ^| ^|  _ \^| __ ^)   ^/ ^^\ ^\ / /^|  _ \ / ___^|
echo   ^| ^|\/^| ^|  / _ \  ^|  ^^^| ^|\  ^| ^|_^| ^| __/   / __ \ V / ^|^| ^|_^| ^| ^|  _
echo   ^|_^|  ^|_^| /_/ \_\ ^|__^^^|_^| \_^|\____/^|_^|    /_/  \_^|_^|  ^|____/ \____^|
echo
echo                 S E T U P   ::   H A C K E R   T H E M E
echo  =========================================================================
echo !RST!

set "DIR=%~dp0"

REM -----------------------------------------------------------------------
REM  Step 1 — Apply registry theme
REM -----------------------------------------------------------------------
echo !CYN! [1/3] Applying WinDBG Hacker color theme...!RST!
if exist "!DIR!hacker.reg" (
    reg import "!DIR!hacker.reg" >nul 2>&1
    if errorlevel 1 (
        echo !YLW!       Reg import needs elevation — trying runas...!RST!
        powershell -Command "Start-Process reg -ArgumentList 'import','\"!DIR!hacker.reg\"' -Verb RunAs -Wait" >nul 2>&1
    )
    echo !BRT!       Theme applied.!RST!
) else (
    echo !YLW!       hacker.reg not found — skipping.!RST!
)
echo.

REM -----------------------------------------------------------------------
REM  Step 2 — Desktop shortcut
REM -----------------------------------------------------------------------
echo !CYN! [2/3] Creating Desktop shortcut...!RST!
set "DESKTOP=%USERPROFILE%\Desktop"
set "LNK=%DESKTOP%\H4CK3R WinDBG.lnk"
powershell -NoProfile -Command ^
  "$ws = New-Object -ComObject WScript.Shell; $sc = $ws.CreateShortcut('%LNK%'); $sc.TargetPath = 'cmd.exe'; $sc.Arguments = '/c \"%DIR%hacker.bat\"'; $sc.WorkingDirectory = '%DIR%'; $sc.WindowStyle = 1; $sc.IconLocation = 'cmd.exe'; $sc.Description = 'H4CK3R WinDBG Launcher'; $sc.Save()" >nul 2>&1
if exist "!LNK!" (
    echo !BRT!       Shortcut created: !LNK!!RST!
) else (
    echo !YLW!       Could not create shortcut (non-fatal).!RST!
)
echo.

REM -----------------------------------------------------------------------
REM  Step 3 — Symbols
REM -----------------------------------------------------------------------
echo !CYN! [3/3] Symbol pre-fetch (optional)...!RST!
echo.
echo !GRN!       The repo already ships with symbols for:!RST!
echo !DIM!         ntdll  kernel32  kernelbase  user32  advapi32  sechost!RST!
echo !DIM!         msvcrt  ws2_32  ntkrnlmp  hal  + WoW64 variants!RST!
echo !DIM!         gdi32  shell32  combase  rpcrt4  ucrtbase  win32u  ...!RST!
echo.
echo !GRN!       These work offline immediately after clone.!RST!
echo !GRN!       To add symbols for your exact Windows build, run:!RST!
echo.
echo !BRT!           fetch_symbols.bat!RST!
echo !BRT!           fetch_symbols.bat /wow64    (include 32-bit stack)!RST!
echo !BRT!           fetch_symbols.bat /kernel   (include kernel binaries)!RST!
echo.

REM -----------------------------------------------------------------------
REM  Done
REM -----------------------------------------------------------------------
echo !GRN!
echo  =========================================================================
echo   Setup complete!  Launch WinDBG with:
echo
echo       hacker.bat                   (x64 target)
echo       hacker.bat /32               (x86 target)
echo       hacker.bat -pn notepad.exe   (attach by name)
echo       hacker.bat -z crash.dmp      (analyze dump)
echo  =========================================================================
echo !RST!
echo.
pause
